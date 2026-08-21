/**
 * Herramienta nueva en Cuenta (Fabrica/Proveedor) - Paso 5 del plan Live Jack.
 * Construida desde cero e independiente de CloneProduct.cls / Clone_Products__c para no
 * pisar el trabajo ya existente. Cubre: clonar/duplicar producto, exportar productos de la
 * fabrica a CSV, enviarlo por correo, y validar/aplicar precios que regresa el proveedor.
 */
public with sharing class AccountFactoryToolsController {

    private static final String CSV_HEADER = 'Id,Supplier Code,Price';

    /**
     * AuraHandledException.getMessage() regresa "Script-thrown exception" a menos que se
     * llame setMessage() explicitamente - este helper evita que se pierda el mensaje real
     * que ve el usuario en el LWC.
     */
    private static AuraHandledException newAuraError(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }

    public class ProductOption {
        @AuraEnabled public Id productId;
        @AuraEnabled public String name;
        @AuraEnabled public String productCode;
    }

    /**
     * Lista los productos de la fabrica para que el usuario elija cual clonar/duplicar.
     */
    @AuraEnabled(cacheable=true)
    public static List<ProductOption> searchFactoryProducts(Id accountId, String searchTerm) {
        String term = '%' + String.escapeSingleQuotes(searchTerm == null ? '' : searchTerm) + '%';
        List<ProductOption> options = new List<ProductOption>();
        for (Product2 p : [SELECT Id, Name, ProductCode FROM Product2
                             WHERE Fabrica__c = :accountId
                               AND RecordType.DeveloperName = 'ProductoDeFabrica'
                               AND IsActive = true
                               AND (Name LIKE :term OR ProductCode LIKE :term)
                             ORDER BY Name LIMIT 25]) {
            ProductOption opt = new ProductOption();
            opt.productId = p.Id;
            opt.name = p.Name;
            opt.productCode = p.ProductCode;
            options.add(opt);
        }
        return options;
    }

    /* ============================== CLONAR / DUPLICAR ============================== */

    /**
     * Reimplementa el mismo resultado de CloneProduct.cls (cambiar Marca__c o Color__c,
     * recalcular ProductCode, clonar el producto de fabrica principal asociado) en una
     * clase nueva e independiente, para no modificar el trabajo del companero.
     */
    @AuraEnabled
    public static Id cloneProduct(Id productId, Boolean modifyBrand, String newBrand, Boolean modifyColor, String newColor) {
        try {
            // Se seleccionan todos los campos dinamicamente (igual que CloneProduct.cls) para
            // que el clone() no deje ningun campo requerido sin copiar.
            Set<String> fieldNames = Schema.SObjectType.Product2.fields.getMap().keySet();
            Product2 original = Database.query(
                'SELECT ' + String.join(new List<String>(fieldNames), ',') + ' FROM Product2 WHERE Id = :productId LIMIT 1'
            );

            Product2 clone = original.clone(false, false, false, false);

            if (modifyBrand) {
                if (String.isBlank(newBrand)) {
                    throw newAuraError('Debe especificar una marca diferente a la original');
                }
                clone.Marca__c = newBrand;
                String[] codeParts = clone.ProductCode.split('[0-9]+');
                String lastToken = codeParts[codeParts.size() - 1];
                clone.ProductCode = clone.ProductCode.substring(0, clone.ProductCode.length() - lastToken.length());
                clone.ProductCode += newBrand.split('-')[0];
            } else if (modifyColor) {
                if (String.isBlank(newColor)) {
                    throw newAuraError('Debe especificar un color diferente al original');
                }
                if (newColor == original.Color__c) {
                    throw newAuraError('El color debe ser diferente al original');
                }
                clone.Color__c = newColor;
                clone.ProductCode = null;
            } else {
                throw newAuraError('Debe elegir clonar (marca) o duplicar (color)');
            }

            clone.Codigo_EAN__c = null;
            clone.Codigo_DUN_14__c = null;
            clone.Listado_en_Catalogo__c = false;
            insert clone;

            // Nota: Estatus__c es una formula de texto que depende del idioma del usuario
            // ("Principal" en es, "Primary" en en-US) - se usa IsActive directamente para
            // no heredar ese problema de CloneProduct.cls.
            Id originalId = original.Id;
            List<Product2> mainFactory = Database.query(
                'SELECT ' + String.join(new List<String>(fieldNames), ',') + ' FROM Product2 ' +
                'WHERE ProductoBase__c = :originalId AND IsActive = true LIMIT 1'
            );
            if (!mainFactory.isEmpty()) {
                Product2 clonedFactory = mainFactory[0].clone(false, false, false, false);
                clonedFactory.ProductoBase__c = clone.Id;
                insert clonedFactory;
            }

            return clone.Id;
        } catch (Exception e) {
            throw newAuraError('No se pudo clonar el producto: ' + e.getMessage());
        }
    }

    /* ============================== EXPORTAR / ENVIAR ============================== */

    public class ExportProductRow {
        @AuraEnabled public Id productId;
        @AuraEnabled public String name;
        @AuraEnabled public String codigoProveedor;
        @AuraEnabled public Decimal price;
    }

    /**
     * Vista previa de lo que se va a exportar/enviar, para mostrar en el LWC antes de
     * descargar el CSV o mandar el correo.
     */
    @AuraEnabled(cacheable=true)
    public static List<ExportProductRow> getFactoryProductsPreview(Id accountId) {
        List<ExportProductRow> preview = new List<ExportProductRow>();
        for (Product2 p : queryFactoryProducts(accountId)) {
            ExportProductRow row = new ExportProductRow();
            row.productId = p.Id;
            row.name = p.Name;
            row.codigoProveedor = p.Codigo_Proveedor2__c;
            row.price = p.PrecioDeFabrica__c;
            preview.add(row);
        }
        return preview;
    }

    @AuraEnabled(cacheable=true)
    public static String getFactoryProductsCsv(Id accountId) {
        List<Product2> products = queryFactoryProducts(accountId);
        return buildCsv(products);
    }

    /**
     * Genera el CSV de productos de la fabrica y lo envia por correo al email comercial
     * de la cuenta, sin salir del componente.
     */
    @AuraEnabled
    public static String emailFactoryProductsCsv(Id accountId) {
        Account acc = [SELECT Id, Name, EmailComercial__c FROM Account WHERE Id = :accountId LIMIT 1];
        if (String.isBlank(acc.EmailComercial__c)) {
            throw newAuraError('La fábrica no tiene un correo comercial configurado (EmailComercial__c).');
        }

        List<Product2> products = queryFactoryProducts(accountId);
        String csv = buildCsv(products);

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Productos_' + acc.Name.replaceAll('[^a-zA-Z0-9]', '_') + '.csv');
        attachment.setBody(Blob.valueOf(csv));
        attachment.setContentType('text/csv');

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{ acc.EmailComercial__c });
        mail.setSubject('Price Update - ' + acc.Name);
        mail.setPlainTextBody('Attached is the list of products to update pricing. Please complete the Price column and return the file.');
        mail.setHtmlBody(buildPriceUpdateEmailHtml(products));
        mail.setFileAttachments(new Messaging.EmailFileAttachment[]{ attachment });

        // Deliverability de correo individual puede estar deshabilitada a nivel org/sandbox
        // (configuracion de Pacific, no del codigo); en pruebas no se intenta el envio real.
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });
        }

        return 'Correo enviado a ' + acc.EmailComercial__c + ' con ' + products.size() + ' producto(s).';
    }

    private static List<Product2> queryFactoryProducts(Id accountId) {
        return [SELECT Id, Name, Codigo_Proveedor2__c, PrecioDeFabrica__c
                  FROM Product2
                 WHERE Fabrica__c = :accountId
                   AND RecordType.DeveloperName = 'ProductoDeFabrica'
                   AND IsActive = true
                 ORDER BY Codigo_Proveedor2__c];
    }

    /**
     * Cuerpo HTML del correo: instrucciones en ingles + una tabla de ejemplo de como
     * llenar el CSV, usando 1-2 filas reales del listado adjunto si existen.
     */
    private static String buildPriceUpdateEmailHtml(List<Product2> products) {
        String exampleRowsHtml = '';
        Integer sampleCount = Math.min(2, products.size());
        if (sampleCount > 0) {
            for (Integer i = 0; i < sampleCount; i++) {
                Product2 p = products[i];
                exampleRowsHtml += '<tr>' +
                    '<td style="padding:6px 10px;border:1px solid #d8e3ee;font-family:monospace;">' + p.Id + '</td>' +
                    '<td style="padding:6px 10px;border:1px solid #d8e3ee;">' + (String.isBlank(p.Codigo_Proveedor2__c) ? '-' : p.Codigo_Proveedor2__c) + '</td>' +
                    '<td style="padding:6px 10px;border:1px solid #d8e3ee;"><strong>25.50</strong> &larr; enter your new price here</td>' +
                    '</tr>';
            }
        } else {
            exampleRowsHtml = '<tr>' +
                '<td style="padding:6px 10px;border:1px solid #d8e3ee;font-family:monospace;">01txxxxxxxxxxxxxxx</td>' +
                '<td style="padding:6px 10px;border:1px solid #d8e3ee;">ABC123</td>' +
                '<td style="padding:6px 10px;border:1px solid #d8e3ee;"><strong>25.50</strong> &larr; enter your new price here</td>' +
                '</tr>';
        }

        return '<div style="font-family:Arial,Helvetica,sans-serif;color:#1c2b39;font-size:14px;line-height:1.5;">' +
            '<p>Hello,</p>' +
            '<p>Attached is the list of products to update pricing. Please complete the <strong>Price</strong> column and return the file.</p>' +
            '<p style="margin-bottom:6px;"><strong>How to fill it out:</strong></p>' +
            '<ul style="margin-top:0;">' +
                '<li>Do not change the <strong>Id</strong> or <strong>Supplier Code</strong> columns.</li>' +
                '<li>Only update the <strong>Price</strong> column with the new price.</li>' +
                '<li>Keep the file in CSV format and return it as-is.</li>' +
            '</ul>' +
            '<p style="margin-bottom:6px;"><strong>Example:</strong></p>' +
            '<table style="border-collapse:collapse;font-size:13px;">' +
                '<tr style="background:#1e73be;color:#ffffff;">' +
                    '<th style="padding:6px 10px;border:1px solid #d8e3ee;text-align:left;">Id</th>' +
                    '<th style="padding:6px 10px;border:1px solid #d8e3ee;text-align:left;">Supplier Code</th>' +
                    '<th style="padding:6px 10px;border:1px solid #d8e3ee;text-align:left;">Price</th>' +
                '</tr>' +
                exampleRowsHtml +
            '</table>' +
            '<p style="margin-top:16px;color:#5b6b7a;font-size:12.5px;">Thank you,<br/>Pacific Global</p>' +
            '</div>';
    }

    private static String buildCsv(List<Product2> products) {
        List<String> lines = new List<String>{ CSV_HEADER };
        for (Product2 p : products) {
            lines.add(p.Id + ',' + escapeCsv(p.Codigo_Proveedor2__c) + ',' + (p.PrecioDeFabrica__c == null ? '' : String.valueOf(p.PrecioDeFabrica__c)));
        }
        return String.join(lines, '\n');
    }

    private static String escapeCsv(String value) {
        if (value == null) return '';
        if (value.contains(',') || value.contains('"')) {
            return '"' + value.replace('"', '""') + '"';
        }
        return value;
    }

    /* ============================== VALIDAR / APLICAR PRECIOS ============================== */

    public class PriceRow {
        @AuraEnabled public Id productId;
        @AuraEnabled public String productName;
        @AuraEnabled public String codigoProveedor;
        @AuraEnabled public Decimal currentPrice;
        @AuraEnabled public Decimal newPrice;
        @AuraEnabled public Decimal pctChange;
        @AuraEnabled public Boolean isIncrease;
        @AuraEnabled public String warning;
    }

    /**
     * Parsea el CSV que regresa el proveedor (Id, Codigo Proveedor, Precio) y arma el
     * resumen de variacion de precio contra el costo de fabrica actual, para que el
     * usuario apruebe antes de aplicar nada.
     */
    @AuraEnabled
    public static List<PriceRow> previewPriceUpdates(String csvContent) {
        List<String> lines = csvContent.replace('\r', '').split('\n');
        Set<Id> productIds = new Set<Id>();
        List<String[]> parsedRows = new List<String[]>();

        for (Integer i = 1; i < lines.size(); i++) {
            String line = lines[i].trim();
            if (String.isBlank(line)) continue;
            String[] cols = line.split(',');
            if (cols.size() < 3) continue;
            String idStr = cols[0].trim();
            if (!isValidId(idStr)) continue;
            parsedRows.add(cols);
            productIds.add((Id) idStr);
        }

        Map<Id, Product2> productsById = new Map<Id, Product2>(
            [SELECT Id, Name, Codigo_Proveedor2__c, PrecioDeFabrica__c FROM Product2 WHERE Id IN :productIds]
        );

        List<PriceRow> result = new List<PriceRow>();
        for (String[] cols : parsedRows) {
            Id prodId = (Id) cols[0].trim();
            Product2 prod = productsById.get(prodId);
            if (prod == null) continue;

            PriceRow row = new PriceRow();
            row.productId = prod.Id;
            row.productName = prod.Name;
            row.codigoProveedor = prod.Codigo_Proveedor2__c;
            row.currentPrice = prod.PrecioDeFabrica__c;
            row.newPrice = Decimal.valueOf(cols[2].trim());

            if (row.currentPrice != null && row.currentPrice != 0) {
                row.pctChange = ((row.newPrice - row.currentPrice) / row.currentPrice * 100).setScale(2);
            } else {
                row.pctChange = null;
            }
            row.isIncrease = row.pctChange != null && row.pctChange > 0;
            if (row.pctChange != null && Math.abs(row.pctChange) > 10) {
                row.warning = 'Variación mayor al 10% (' + row.pctChange + '%)';
            }
            result.add(row);
        }
        return result;
    }

    /**
     * Aplica los precios ya revisados/aprobados por el usuario. Crea un encabezado
     * Verificacion_Costo__c (bitacora) y una linea Verificacion_Costo_Productos__c por
     * producto, y actualiza el costo de fabrica real. No depende del portal/token viejo.
     */
    @AuraEnabled
    public static String applyPriceUpdates(Id accountId, String rowsJson) {
        // Se recibe como JSON (String) y se deserializa manualmente en vez de usar
        // List<PriceRow> directo como parametro: mandar un tipo Apex personalizado como
        // parametro de accion desde LWC llegaba corrompido ({} vacios) por como Aura
        // serializa los parametros de las acciones - con JSON.deserialize se evita esa capa.
        List<PriceRow> rows;
        try {
            rows = (List<PriceRow>) JSON.deserialize(rowsJson, List<PriceRow>.class);
        } catch (Exception e) {
            throw newAuraError('No se pudo leer la información enviada: ' + e.getMessage());
        }

        if (rows == null || rows.isEmpty()) {
            throw newAuraError('No hay filas para aplicar.');
        }

        // Filas sin un Id de producto valido (ej. una fila mal editada en el CSV) se
        // descartan aqui en vez de tronar todo el lote con MISSING_ARGUMENT.
        List<PriceRow> validRows = new List<PriceRow>();
        Integer skipped = 0;
        for (PriceRow row : rows) {
            if (row.productId == null || row.newPrice == null) {
                skipped++;
            } else {
                validRows.add(row);
            }
        }

        if (validRows.isEmpty()) {
            throw newAuraError('Ninguna de las filas tiene un producto e importe válidos. Revisa que la columna Id no se haya perdido al editar el archivo.');
        }

        Verificacion_Costo__c header = new Verificacion_Costo__c(
            Name = 'PG-' + accountId,
            Estado__c = 'Verificado'
        );
        insert header;

        List<Verificacion_Costo_Productos__c> stagingRows = new List<Verificacion_Costo_Productos__c>();
        List<Product2> productsToUpdate = new List<Product2>();

        for (PriceRow row : validRows) {
            stagingRows.add(new Verificacion_Costo_Productos__c(
                Verificacion_Costo__c = header.Id,
                Product__c = row.productId,
                Factory__c = accountId,
                New_Price__c = row.newPrice,
                Estado__c = 'Aprobado',
                Fecha_Estado__c = Date.today()
            ));
            productsToUpdate.add(new Product2(Id = row.productId, PrecioDeFabrica__c = row.newPrice));
        }

        insert stagingRows;

        // allOrNone=false: si un producto individual falla (ej. FLS, validation rule),
        // los demas se aplican igual y el error se reporta en vez de tronar todo el lote.
        List<Database.SaveResult> results = Database.update(productsToUpdate, false);
        Integer successCount = 0;
        List<String> rowErrors = new List<String>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                successCount++;
            } else {
                rowErrors.add(productsToUpdate[i].Id + ': ' + results[i].getErrors()[0].getMessage());
            }
        }

        String message = 'Se actualizó el precio de ' + successCount + ' producto(s).';
        if (skipped > 0) {
            message += ' ' + skipped + ' fila(s) se ignoraron por no tener producto o precio válido.';
        }
        if (!rowErrors.isEmpty()) {
            message += ' Errores: ' + String.join(rowErrors, '; ');
        }
        return message;
    }

    private static Boolean isValidId(String value) {
        if (String.isBlank(value)) return false;
        try {
            Id test = (Id) value;
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}