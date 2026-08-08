@IsTest
private class ProductNamingServiceTest {

    private static final String SUBFAMILIA_TEST = '5-Folding Furniture';
    private static final String CLASE_TEST = '01-Utility Folding Tables (HDPE)';

    private static Id getProductoRtId() {
        Map<String, Schema.RecordTypeInfo> rtInfoByDevName =
            Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName();

        System.assert(
            rtInfoByDevName.containsKey('Producto'),
            'Debe existir el RecordType Producto en Product2'
        );

        return rtInfoByDevName.get('Producto').getRecordTypeId();
    }

    private static Id getProductoDeFabricaRtId() {
        Map<String, Schema.RecordTypeInfo> rtInfoByDevName =
            Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName();

        if (rtInfoByDevName.containsKey('ProductoDeFabrica')) {
            return rtInfoByDevName.get('ProductoDeFabrica').getRecordTypeId();
        }
        return null;
    }

    private static String getAnyActivePicklistValue(Schema.SObjectField fieldRef) {
        for (Schema.PicklistEntry pe : fieldRef.getDescribe().getPicklistValues()) {
            if (pe.isActive()) {
                return pe.getValue();
            }
        }

        System.assert(false, 'No se encontró un valor activo para el campo ' + String.valueOf(fieldRef));
        return null;
    }

    private static String tokenBeforeDash(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        Integer dashPos = value.indexOf('-');
        return dashPos == -1 ? value.trim() : value.substring(0, dashPos).trim();
    }

    private static Integer extractSequence(String productCode, String prefix) {
        Integer startPos = prefix.length();
        Integer endPos = startPos + 3;
        return Integer.valueOf(productCode.substring(startPos, endPos));
    }

    private static Product2 buildProductoBase(String nameSuffix) {
        return new Product2(
            RecordTypeId = getProductoRtId(),
            Name = 'Producto Test ' + nameSuffix,
            Family = getAnyActivePicklistValue(Product2.Family),
            Subfamilia__c = SUBFAMILIA_TEST,
            Clase__c = CLASE_TEST,
            Marca__c = getAnyActivePicklistValue(Product2.Marca__c)
        );
    }

    @IsTest
    static void testAssignCodesBeforeInsert_NullAndEmpty() {
        Test.startTest();
        ProductNamingService.assignCodesBeforeInsert(null);
        ProductNamingService.assignCodesBeforeInsert(new List<Product2>());
        Test.stopTest();

        System.assert(true, 'No debe lanzar excepción con lista null o vacía');
    }

    @IsTest
    static void testAssignCodesBeforeInsert_AssignsOnlyToEligibleProducts() {
        Product2 productoSinCodigo = buildProductoBase('Sin Codigo');

        Product2 productoConCodigo = buildProductoBase('Con Codigo');
        productoConCodigo.ProductCode = 'MANUAL001';

        Id prodFabRtId = getProductoDeFabricaRtId();
        Product2 productoDeFabrica;
        if (prodFabRtId != null) {
            productoDeFabrica = new Product2(
                RecordTypeId = prodFabRtId,
                Name = 'Producto Fabrica Test',
                Family = getAnyActivePicklistValue(Product2.Family),
                Subfamilia__c = SUBFAMILIA_TEST,
                Clase__c = CLASE_TEST,
                Marca__c = getAnyActivePicklistValue(Product2.Marca__c)
            );
        }

        List<Product2> scope = new List<Product2>{ productoSinCodigo, productoConCodigo };
        if (productoDeFabrica != null) {
            scope.add(productoDeFabrica);
        }

        Test.startTest();
        ProductNamingService.assignCodesBeforeInsert(scope);
        Test.stopTest();

        System.assertNotEquals(
            null,
            productoSinCodigo.ProductCode,
            'Debe asignar ProductCode al producto elegible sin código'
        );

        System.assertEquals(
            'MANUAL001',
            productoConCodigo.ProductCode,
            'Debe respetar el ProductCode informado manualmente'
        );

        if (productoDeFabrica != null) {
            System.assertEquals(
                null,
                productoDeFabrica.ProductCode,
                'No debe asignar ProductCode a otros Record Types'
            );
        }
    }

    @IsTest
    static void testAssignCodesBeforeInsert_GeneratesExpectedFormat() {
        Product2 producto = buildProductoBase('Formato');

        String expectedPrefix =
            tokenBeforeDash(producto.Family).toUpperCase() +
            tokenBeforeDash(producto.Subfamilia__c).toUpperCase() +
            tokenBeforeDash(producto.Clase__c).toUpperCase();

        String expectedBrandToken = tokenBeforeDash(producto.Marca__c).toUpperCase();

        Test.startTest();
        ProductNamingService.assignCodesBeforeInsert(new List<Product2>{ producto });
        Test.stopTest();

        System.assertNotEquals(null, producto.ProductCode, 'Debe generar ProductCode');
        System.assert(
            producto.ProductCode.startsWith(expectedPrefix),
            'El código debe iniciar con el prefijo esperado'
        );
        System.assert(
            producto.ProductCode.endsWith(expectedBrandToken),
            'El código debe terminar con el token de Marca__c'
        );
    }

    @IsTest
    static void testAssignCodesBeforeInsert_GeneratesConsecutiveCodesInSameBatch() {
        Product2 producto1 = buildProductoBase('Lote 1');
        Product2 producto2 = new Product2(
            RecordTypeId = producto1.RecordTypeId,
            Name = 'Producto Test Lote 2',
            Family = producto1.Family,
            Subfamilia__c = producto1.Subfamilia__c,
            Clase__c = producto1.Clase__c,
            Marca__c = producto1.Marca__c
        );

        String prefix =
            tokenBeforeDash(producto1.Family).toUpperCase() +
            tokenBeforeDash(producto1.Subfamilia__c).toUpperCase() +
            tokenBeforeDash(producto1.Clase__c).toUpperCase();

        Test.startTest();
        ProductNamingService.assignCodesBeforeInsert(new List<Product2>{ producto1, producto2 });
        Test.stopTest();

        System.assertNotEquals(null, producto1.ProductCode, 'El primer producto debe recibir código');
        System.assertNotEquals(null, producto2.ProductCode, 'El segundo producto debe recibir código');
        System.assertNotEquals(producto1.ProductCode, producto2.ProductCode, 'Los códigos no deben repetirse');

        Integer seq1 = extractSequence(producto1.ProductCode, prefix);
        Integer seq2 = extractSequence(producto2.ProductCode, prefix);

        System.assertEquals(
            seq1 + 1,
            seq2,
            'El segundo producto debe incrementar en 1 el correlativo del primero'
        );
    }
}