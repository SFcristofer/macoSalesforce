@IsTest
private class TestProductoTrigger {

    private static final String SUBFAMILIA_BASE = '2-Outdoor Shades & Structures';
    private static final String CLASE_BASE = '03-Awnings';

    private static Id getProductoRtId() {
        return Schema.SObjectType.Product2
            .getRecordTypeInfosByDeveloperName()
            .get('Producto')
            .getRecordTypeId();
    }

    private static String tokenBeforeDash(String value) {
        if (String.isBlank(value)) {
            return null;
        }

        Integer dashPos = value.indexOf('-');
        return dashPos == -1 ? value.trim() : value.substring(0, dashPos).trim();
    }

    private static String buildExpectedPrefix(Product2 p) {
        return tokenBeforeDash(p.Family).toUpperCase()
             + tokenBeforeDash(p.Subfamilia__c).toUpperCase()
             + tokenBeforeDash(p.Clase__c).toUpperCase();
    }

    private static Integer extractSequence(String productCode, String prefix) {
        Integer startPos = prefix.length();
        Integer endPos = startPos + 3;
        return Integer.valueOf(productCode.substring(startPos, endPos));
    }

    private static Product2 buildProductoBase(TestUtil tu, String nameSuffix) {
        return new Product2(
            RecordTypeId = getProductoRtId(),
            Name = 'Producto Test ' + nameSuffix,
            Family = tu.familyProductoGarden,
            Subfamilia__c = SUBFAMILIA_BASE,
            Clase__c = CLASE_BASE,
            Marca__c = tu.marcaProductoGarden,
            M3Unidad__c = 0.5,
            UnidadesPorMasterBox__c = 2,
            UnidadesHQ__c = 1000,
            UnidadesContainer20__c = 400,
            IsActive = false,
            MasterboxAltoCm__c = '10',
            MasterboxAnchoCm__c = '10',
            MasterboxLargoCm__c = '10',
            Packaging__c = '1-BROWN BOX',
            Listado_en_Catalogo__c = false
        );
    }

    @IsTest
    static void testInsertProductoBase_GeneraCodigoYEscandallo() {
        TestUtil tu = new TestUtil();
        tu.initSoloBase();

        Product2 prod = buildProductoBase(tu, 'Insert');

        Test.startTest();
        ProductTriggerHelper.resetRunForTesting();
        insert prod;
        Test.stopTest();

        Product2 inserted = [
            SELECT Id,
                   ProductCode,
                   MasterboxM3__c,
                   Family,
                   Subfamilia__c,
                   Clase__c,
                   Marca__c,
                   C_digo_base_SIN_MARCA__c
            FROM Product2
            WHERE Id = :prod.Id
        ];

        String expectedPrefix = buildExpectedPrefix(inserted);
        String expectedBrandToken = tokenBeforeDash(inserted.Marca__c).toUpperCase();

        System.assertNotEquals(null, inserted.ProductCode, 'Debe generarse ProductCode');
        System.assert(inserted.ProductCode.startsWith(expectedPrefix), 'El código debe iniciar con el prefijo esperado');
        System.assert(inserted.ProductCode.endsWith(expectedBrandToken), 'El código debe terminar con el token de marca');
        System.assertNotEquals(null, inserted.C_digo_base_SIN_MARCA__c, 'Debe poblarse el código base sin marca');
        System.assertNotEquals(null, inserted.MasterboxM3__c, 'Debe calcularse el volumen MasterboxM3__c');

        List<EscandalloLineItem__c> items = tu.getItemsEscandalloForBase(prod.Id);
        System.assertEquals(1, items.size(), 'Debe existir un EscandalloLineItem para el producto base');
    }

    @IsTest
    static void testInsertSecuencial_MismoPrefijoIncrementaConsecutivo() {
        TestUtil tu = new TestUtil();
        tu.initSoloBase();

        Product2 prod1 = buildProductoBase(tu, 'Secuencia 1');
        Product2 prod2 = buildProductoBase(tu, 'Secuencia 2');

        Test.startTest();
        ProductTriggerHelper.resetRunForTesting();
        insert new List<Product2>{ prod1, prod2 };
        Test.stopTest();

        List<Product2> inserted = [
            SELECT Id, ProductCode, Family, Subfamilia__c, Clase__c, Marca__c
            FROM Product2
            WHERE Id IN :new Set<Id>{ prod1.Id, prod2.Id }
            ORDER BY ProductCode ASC
        ];

        System.assertEquals(2, inserted.size(), 'Deben insertarse ambos productos');

        String prefix1 = buildExpectedPrefix(inserted[0]);
        String prefix2 = buildExpectedPrefix(inserted[1]);

        System.assertEquals(prefix1, prefix2, 'Ambos productos deben compartir el mismo prefijo');

        Integer seq1 = extractSequence(inserted[0].ProductCode, prefix1);
        Integer seq2 = extractSequence(inserted[1].ProductCode, prefix2);

        System.assertEquals(seq1 + 1, seq2, 'El segundo producto debe incrementar el correlativo en 1');
    }

    @IsTest
    static void testInsertRespetaProductCodePredefinido() {
        TestUtil tu = new TestUtil();
        tu.initSoloBase();

        Product2 prod = buildProductoBase(tu, 'Preset');
        prod.ProductCode = 'CUSTOM01';

        Test.startTest();
        ProductTriggerHelper.resetRunForTesting();
        insert prod;
        Test.stopTest();

        Product2 inserted = [
            SELECT ProductCode
            FROM Product2
            WHERE Id = :prod.Id
        ];

        System.assertEquals('CUSTOM01', inserted.ProductCode, 'Debe respetar el ProductCode enviado');
    }

    @IsTest
    static void testUpdateProductoDimensions_RecalculaVolumen() {
        TestUtil tu = new TestUtil();
        tu.initSoloBase();

        Product2 prod = tu.productosBase[0];
        Decimal oldVolume = [
            SELECT MasterboxM3__c
            FROM Product2
            WHERE Id = :prod.Id
        ].MasterboxM3__c;

        prod.MasterboxAltoCm__c = '20';
        prod.MasterboxAnchoCm__c = '20';
        prod.MasterboxLargoCm__c = '20';

        Test.startTest();
        ProductTriggerHelper.resetRunForTesting();
        update prod;
        Test.stopTest();

        Product2 updated = [
            SELECT MasterboxM3__c
            FROM Product2
            WHERE Id = :prod.Id
        ];

        System.assertNotEquals(oldVolume, updated.MasterboxM3__c, 'Debe recalcularse el volumen al actualizar dimensiones');
    }

    @IsTest
    static void testDeleteProductoBase_EliminaEscandalloLineItem() {
        TestUtil tu = new TestUtil();
        tu.initSoloBase();

        Product2 prod = tu.productosBase[0];

        List<EscandalloLineItem__c> itemsBefore = tu.getItemsEscandalloForBase(prod.Id);
        System.assertEquals(1, itemsBefore.size(), 'Debe existir el EscandalloLineItem antes del delete');

        Test.startTest();
        ProductTriggerHelper.resetRunForTesting();
        delete prod;
        Test.stopTest();

        Integer itemsAfter = [
            SELECT COUNT()
            FROM EscandalloLineItem__c
            WHERE Producto__c = :prod.Id
        ];
        System.assertEquals(0, itemsAfter, 'Debe eliminarse el EscandalloLineItem al borrar el producto base');
    }

    @IsTest
    static void testInsertProductoDeFabrica_CreaPricebookEntries() {
        TestUtil tu = new TestUtil();

        Test.startTest();
        tu.initTestData();
        Test.stopTest();

        List<Product2> fabProducts = tu.getAllPDFUpdated();

        System.assert(fabProducts.size() > 0, 'Deben existir productos de fábrica');

        Integer totalEntries = 0;
        for (Product2 p : fabProducts) {
            System.assertNotEquals(null, p.ProductoBase__c, 'El producto de fábrica debe estar ligado a un producto base');
            totalEntries += p.PricebookEntries.size();
        }

        System.assert(totalEntries > 0, 'Los productos de fábrica deben tener PricebookEntries');
    }

    @IsTest
    static void testInsertCalculaTodosLosVolumenes() {
        TestUtil tu = new TestUtil();
        tu.initSoloBase();

        Product2 prod = new Product2(
            RecordTypeId = getProductoRtId(),
            Name = 'Producto Test Volumenes',
            Family = tu.familyProductoGarden,
            Subfamilia__c = SUBFAMILIA_BASE,
            Clase__c = CLASE_BASE,
            Marca__c = tu.marcaProductoGarden,
            M3Unidad__c = 0.5,
            UnidadesPorMasterBox__c = 2,
            UnidadesHQ__c = 1000,
            UnidadesContainer20__c = 400,
            IsActive = false,
            MasterboxAltoCm__c = '50',
            MasterboxAnchoCm__c = '40',
            MasterboxLargoCm__c = '30',
            CajaAltoCm__c = '25',
            CajaAnchoCm__c = '20',
            CajaLargoCm__c = '15',
            ProductoAltoCm__c = '10',
            ProductoAnchoCm__c = '8',
            ProductoLargoCm__c = '6',
            Packaging__c = '1-BROWN BOX',
            Listado_en_Catalogo__c = false
        );

        Test.startTest();
        ProductTriggerHelper.resetRunForTesting();
        insert prod;
        Test.stopTest();

        Product2 inserted = [
            SELECT MasterboxM3__c, CajaM3__c, ProductoM3__c
            FROM Product2
            WHERE Id = :prod.Id
        ];

        System.assertNotEquals(null, inserted.MasterboxM3__c, 'Debe calcularse MasterboxM3__c');
        System.assertNotEquals(null, inserted.CajaM3__c, 'Debe calcularse CajaM3__c');
        System.assertNotEquals(null, inserted.ProductoM3__c, 'Debe calcularse ProductoM3__c');
    }

    @IsTest
    static void testProductTriggerHelper_PublicMethods() {
        TestUtil tu = new TestUtil();
        tu.initSoloBase();

        ProductTriggerHelper helper = new ProductTriggerHelper();

        // isCalculable
        System.assertEquals(true, helper.isCalculable('100', '100', '100'),
            'Debe devolver true cuando alto, largo y ancho son numéricos y mayores a 0');
        System.assertEquals(false, helper.isCalculable(null, '100', '100'),
            'Debe devolver false si algún valor es null');
        System.assertEquals(false, helper.isCalculable('ABC', '100', '100'),
            'Debe devolver false si algún valor no es numérico');
        System.assertEquals(false, helper.isCalculable('0', '100', '100'),
            'Debe devolver false si algún valor es 0');

        // calculateVolume
        System.assertEquals(1.0, helper.calculateVolume('100', '100', '100'),
            '100cm x 100cm x 100cm debe ser 1.0 m3');
        System.assertEquals(null, helper.calculateVolume('ABC', '100', '100'),
            'Debe devolver null cuando no puede convertir los valores a número');

        // compareProducts
        Product2 oldProd = [
            SELECT Id, Name,
                MasterboxAltoCm__c, MasterboxAnchoCm__c, MasterboxLargoCm__c, MasterboxM3__c,
                Masterbox2AltoCm__c, Masterbox2AnchoCm__c, Masterbox2LargoCm__c, Masterbox2M3__c,
                Masterbox3AltoCm__c, Masterbox3AnchoCm__c, Masterbox3LargoCm__c, Masterbox3M3__c,
                Masterbox4AltoCm__c, Masterbox4AnchoCm__c, Masterbox4LargoCm__c, Masterbox4M3__c,
                Masterbox5AltoCm__c, Masterbox5AnchoCm__c, Masterbox5LargoCm__c, Masterbox5M3__c,
                Masterbox6AltoCm__c, Masterbox6AnchoCm__c, Masterbox6LargoCm__c, Masterbox6M3__c,
                CajaAltoCm__c, CajaAnchoCm__c, CajaLargoCm__c, CajaM3__c,
                ProductoAltoCm__c, ProductoAnchoCm__c, ProductoLargoCm__c, ProductoM3__c
            FROM Product2
            WHERE Id = :tu.productosBase[0].Id
        ];

        Product2 newProd = oldProd.clone(true, false, false, false);

        newProd.MasterboxAltoCm__c = '20';
        newProd.MasterboxAnchoCm__c = '20';
        newProd.MasterboxLargoCm__c = '20';

        newProd.Masterbox2AltoCm__c = '20';
        newProd.Masterbox2AnchoCm__c = '20';
        newProd.Masterbox2LargoCm__c = '20';

        newProd.Masterbox3AltoCm__c = '20';
        newProd.Masterbox3AnchoCm__c = '20';
        newProd.Masterbox3LargoCm__c = '20';

        newProd.Masterbox4AltoCm__c = '20';
        newProd.Masterbox4AnchoCm__c = '20';
        newProd.Masterbox4LargoCm__c = '20';

        newProd.Masterbox5AltoCm__c = '20';
        newProd.Masterbox5AnchoCm__c = '20';
        newProd.Masterbox5LargoCm__c = '20';

        newProd.Masterbox6AltoCm__c = '20';
        newProd.Masterbox6AnchoCm__c = '20';
        newProd.Masterbox6LargoCm__c = '20';

        newProd.CajaAltoCm__c = '30';
        newProd.CajaAnchoCm__c = '20';
        newProd.CajaLargoCm__c = '10';

        newProd.ProductoAltoCm__c = '40';
        newProd.ProductoAnchoCm__c = '30';
        newProd.ProductoLargoCm__c = '20';

        Map<Id, Product2> oldMap = new Map<Id, Product2>{
            oldProd.Id => oldProd
        };

        Test.startTest();
        helper.compareProducts(new List<Product2>{ newProd }, oldMap);
        Test.stopTest();

        System.assertNotEquals(oldProd.MasterboxM3__c, newProd.MasterboxM3__c,
            'Debe recalcular MasterboxM3__c cuando cambian dimensiones');
        System.assertNotEquals(null, newProd.CajaM3__c,
            'Debe calcular CajaM3__c cuando cambian dimensiones');
        System.assertNotEquals(null, newProd.ProductoM3__c,
            'Debe calcular ProductoM3__c cuando cambian dimensiones');

        System.assertEquals(0.008000000000000002, newProd.MasterboxM3__c,
            '20x20x20 cm debe ser 0.008 m3');
        System.assertEquals(0.006, newProd.CajaM3__c,
            '30x20x10 cm debe ser 0.006 m3');
        System.assertEquals(0.024, newProd.ProductoM3__c,
            '40x30x20 cm debe ser 0.024 m3');
    }
}