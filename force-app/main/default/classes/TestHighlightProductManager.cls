@isTest
private class TestHighlightProductManager {
    
    @TestSetup
    static void makeData(){
        String marcaValue;
        String marcaValueUpper;
        String familyValue;
        String familyValueUpper;
        
        String marcaProductoGarden;        
        String marcaProductoOutdoorSoriana;
        String familyProductoGarden;
        
        Schema.DescribeFieldResult fieldResult;
        List<Schema.PicklistEntry> ple;
        
        TestUtil tu = new TestUtil();
        tu.initSoloBase();

        fieldResult = Product2.Marca__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple) {
            marcaValue = pickListVal.getLabel();
            marcaValueUpper = marcaValue.toUpperCase();
            if(marcaValueUpper.contains('GARDEN')) {
                marcaProductoGarden = marcaValue;
            }
            if(marcaValueUpper.contains('OUTDOOR') && marcaValueUpper.contains('SORIANA')) {
                marcaProductoOutdoorSoriana = marcaValue;
            }
        }


        fieldResult = Product2.Family.getDescribe();
        ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple) {
            familyValue = pickListVal.getLabel();
            familyValueUpper = familyValue.toUpperCase();
            if(familyValueUpper.contains('GARDEN')) {
                familyProductoGarden = familyValue;
            }
        }

        Id prodRTId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Producto').getRecordTypeId();
        List<Product2> productosBase = new List<Product2>();
        for(Integer i = 0; i < 4; i++){
            productosBase.add(new Product2(Name = i == 0 ? 'Chair' : 'Sofa ' + String.valueOf(i),
                                        RecordTypeId = prodRTId, 
                                        M3Unidad__c = 0.5,
                                        UnidadesPorMasterBox__c = 2,
                                        UnidadesHQ__c = 1000,
                                        UnidadesContainer20__c = 400,
                                        isActive = false,
                                        MasterboxAltoCm__c = i == 0 ? '100' : '10',
                                        MasterboxAnchoCm__c = i == 0 ? '100' : '10',
                                        MasterboxLargoCm__c = i == 0 ? '100' : '10',
                                        MasterboxM3__c = i == 0 ? 1 : 0.001,
                                        Family = familyProductoGarden,
                                        Subfamilia__c = '1-Muebles de Jardín',
                                        Clase__c = '01-Resina y Plástico',
                                        Marca__c = marcaProductoGarden,
                                        Packaging__c = i == 0 ? '1-CAJA MARRON' : '9-CAJA COLOR',
                                        Listado_en_Catalogo__c = true,
                                        Best_Seller_Global__c = i == 0 ? true : false));
        }
        insert productosBase;
    }

    @isTest
    static void TestAllMethods() {
        Map<Id, Boolean> results = HighlightProductManager.getHighlightedAsNew();
        system.assertEquals(results.size(), 6); //Accounts for the two products created in TestUtil InitSoloBase
        results = HighlightProductManager.getBestSellerGlobal();
        system.assertEquals(results.size(), 1);
        results = HighlightProductManager.getBestSellerInNOut();
        system.assertEquals(results.size(), 0);
    }
}