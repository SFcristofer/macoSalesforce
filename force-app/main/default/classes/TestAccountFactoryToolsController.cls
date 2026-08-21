@isTest
private class TestAccountFactoryToolsController {

    @testSetup
    static void setup() {
        TestUtil testUtil = new TestUtil();
        testUtil.initTestData();

        // ProductCode predecible para poder probar el recalculo de codigo en cloneProduct.
        // El patron (heredado de CloneProduct.cls) reemplaza lo que viene DESPUES del ultimo
        // numero por el prefijo de la marca nueva, ej. 'ABC-99A' + marca 'XYZ-Home' -> 'ABC-99XYZ'.
        Product2 baseProduct = testUtil.productosBase[0];
        baseProduct.ProductCode = 'ABC-99A';
        update baseProduct;
    }

    private static Account getFabrica() {
        return [SELECT Id, EmailComercial__c FROM Account WHERE RecordType.DeveloperName = 'Proveedor' LIMIT 1];
    }

    private static Product2 getBaseProduct() {
        return [SELECT Id, ProductCode, Marca__c, Color__c FROM Product2
                 WHERE RecordType.DeveloperName = 'Producto' ORDER BY Name LIMIT 1];
    }

    private static Product2 getFactoryProduct() {
        return [SELECT Id, PrecioDeFabrica__c, ProductoBase__c FROM Product2
                 WHERE RecordType.DeveloperName = 'ProductoDeFabrica' ORDER BY Name LIMIT 1];
    }

    @isTest
    static void testSearchFactoryProducts() {
        Account fabrica = getFabrica();

        Test.startTest();
        List<AccountFactoryToolsController.ProductOption> options =
            AccountFactoryToolsController.searchFactoryProducts(fabrica.Id, '');
        Test.stopTest();

        System.assert(!options.isEmpty(), 'Debe encontrar al menos un producto de la fábrica');
    }

    @isTest
    static void testCloneProductBrandMode() {
        Product2 base = getBaseProduct();

        Test.startTest();
        Id clonedId = AccountFactoryToolsController.cloneProduct(base.Id, true, 'B-!DEA Home', false, null);
        Test.stopTest();

        Product2 cloned = [SELECT Id, Marca__c, ProductCode FROM Product2 WHERE Id = :clonedId];
        System.assertEquals('B-!DEA Home', cloned.Marca__c, 'La marca del clon debe ser la nueva');
        System.assertEquals('ABC-99B', cloned.ProductCode, 'El sufijo despues del numero debe reemplazarse por el prefijo de la marca nueva');

        // El producto de fabrica principal tambien debe haberse clonado, apuntando al nuevo producto base
        List<Product2> clonedFactory = [SELECT Id, ProductoBase__c FROM Product2 WHERE ProductoBase__c = :clonedId];
        System.assertEquals(1, clonedFactory.size(), 'Debe clonarse tambien el producto de fabrica principal asociado');
    }

    @isTest
    static void testCloneProductColorMode() {
        Product2 base = getBaseProduct();

        Test.startTest();
        Id clonedId = AccountFactoryToolsController.cloneProduct(base.Id, false, null, true, 'Rojo');
        Test.stopTest();

        Product2 cloned = [SELECT Id, Color__c FROM Product2 WHERE Id = :clonedId];
        System.assertEquals('Rojo', cloned.Color__c, 'El color del clon debe ser el nuevo');
    }

    @isTest
    static void testCloneProductWithoutModeThrows() {
        Product2 base = getBaseProduct();
        Boolean errored = false;

        Test.startTest();
        try {
            AccountFactoryToolsController.cloneProduct(base.Id, false, null, false, null);
        } catch (AuraHandledException e) {
            errored = true;
        }
        Test.stopTest();

        System.assert(errored, 'Debe lanzar error si no se elige clonar ni duplicar');
    }

    @isTest
    static void testGetFactoryProductsCsv() {
        Account fabrica = getFabrica();

        Test.startTest();
        String csv = AccountFactoryToolsController.getFactoryProductsCsv(fabrica.Id);
        Test.stopTest();

        System.assert(csv.startsWith('Id,Supplier Code,Price'), 'El CSV debe iniciar con el encabezado esperado');
        System.assert(csv.split('\n').size() > 1, 'El CSV debe tener al menos 1 fila de datos');
    }

    @isTest
    static void testEmailFactoryProductsCsv_Success() {
        Account fabrica = getFabrica(); // ya tiene EmailComercial__c desde TestUtil

        Test.startTest();
        String result = AccountFactoryToolsController.emailFactoryProductsCsv(fabrica.Id);
        Test.stopTest();

        System.assert(result.contains('Correo enviado'), 'Debe confirmar el envio del correo');
    }

    @isTest
    static void testEmailFactoryProductsCsv_SinEmailLanzaError() {
        Account fabrica = getFabrica();
        fabrica.EmailComercial__c = null;
        update fabrica;

        Boolean errored = false;
        Test.startTest();
        try {
            AccountFactoryToolsController.emailFactoryProductsCsv(fabrica.Id);
        } catch (AuraHandledException e) {
            errored = true;
        }
        Test.stopTest();

        System.assert(errored, 'Debe lanzar error si la fabrica no tiene EmailComercial__c');
    }

    @isTest
    static void testPreviewAndApplyPriceUpdates() {
        Account fabrica = getFabrica();
        Product2 factoryProduct = getFactoryProduct(); // PrecioDeFabrica__c = 20 (ver TestUtil)

        String csv = 'Id,Supplier Code,Price\n' + factoryProduct.Id + ',ABC123,25';

        Test.startTest();
        List<AccountFactoryToolsController.PriceRow> rows = AccountFactoryToolsController.previewPriceUpdates(csv);
        System.assertEquals(1, rows.size(), 'Debe parsear 1 fila valida');
        System.assertEquals(20, rows[0].currentPrice, 'Debe traer el precio actual del producto');
        System.assertEquals(25, rows[0].newPrice, 'Debe traer el precio nuevo del CSV');
        System.assertEquals(25, rows[0].pctChange, 'De 20 a 25 es un incremento del 25%');
        System.assert(rows[0].isIncrease, 'Debe marcarse como incremento');
        System.assert(rows[0].warning != null, 'Un incremento de 25% debe superar el umbral de advertencia (10%)');

        String applyResult = AccountFactoryToolsController.applyPriceUpdates(fabrica.Id, JSON.serialize(rows));
        Test.stopTest();

        System.assert(applyResult.contains('1 producto'), 'Debe confirmar 1 producto actualizado');

        Product2 updated = [SELECT PrecioDeFabrica__c FROM Product2 WHERE Id = :factoryProduct.Id];
        System.assertEquals(25, updated.PrecioDeFabrica__c, 'El precio de fabrica debe quedar actualizado');

        List<Verificacion_Costo_Productos__c> staging = [SELECT Id, Estado__c, New_Price__c
                                                            FROM Verificacion_Costo_Productos__c
                                                           WHERE Product__c = :factoryProduct.Id];
        System.assertEquals(1, staging.size(), 'Debe quedar 1 registro de bitacora');
        System.assertEquals('Aprobado', staging[0].Estado__c);
    }

    @isTest
    static void testPreviewPriceUpdatesSinCambioNoMarcaAdvertencia() {
        Product2 factoryProduct = getFactoryProduct();
        String csv = 'Id,Supplier Code,Price\n' + factoryProduct.Id + ',ABC123,20';

        Test.startTest();
        List<AccountFactoryToolsController.PriceRow> rows = AccountFactoryToolsController.previewPriceUpdates(csv);
        Test.stopTest();

        System.assertEquals(0, rows[0].pctChange, 'Sin cambio de precio, la variacion debe ser 0%');
        System.assert(rows[0].warning == null, 'Sin variacion no debe haber advertencia');
    }
}