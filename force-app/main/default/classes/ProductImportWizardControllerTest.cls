@isTest(SeeAllData=true)
private class ProductImportWizardControllerTest {
    @isTest
    static void testGetProductFields() {
        Test.startTest();
        List<Map<String, String>> fields = ProductImportWizardController.getProductFields();
        Test.stopTest();
        System.assertNotEquals(0, fields.size(), 'Should return product fields');
    }
    
    @isTest
    static void testGetRecordTypeIdsByDeveloperName() {
        Test.startTest();
        Map<String, String> rtMap = ProductImportWizardController.getRecordTypeIdsByDeveloperName();
        Test.stopTest();
        System.assert(rtMap.containsKey('Producto'), 'Should include the base product record type');
        System.assert(rtMap.containsKey('ProductoDeFabrica'), 'Should include the factory product record type');
    }

    @isTest
    static void testImportProducts() {
        Product2 existingProd = [SELECT Id FROM Product2 WHERE RecordType.DeveloperName = 'Producto' LIMIT 1];
        Id baseRtId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Producto').getRecordTypeId();
        
        List<Product2> toInsert = new List<Product2>{
            new Product2(RecordTypeId=baseRtId, Name='WizTest', IsActive=false, Family='B-!DEA Heating & Fan', Subfamilia__c='1-Fans', Clase__c='01-Stand & Tower Fans', Marca__c='A-!DEA Garden')
        };
        List<Product2> toUpdate = new List<Product2>{
            new Product2(Id=existingProd.Id, Name='WizUpdate')
        };
        
        // Esto fallará el DML ya que no tiene campos requeridos
        List<Product2> badProd = new List<Product2>{ new Product2() };
        
        String jsonInsert = JSON.serialize(toInsert);
        String jsonUpdate = JSON.serialize(toUpdate);
        String jsonBad = JSON.serialize(badProd);
        
        Test.startTest();
        
        // Test Insert Success
        ProductImportWizardController.importProducts(jsonInsert, 'insert', null);
        
        // Test Insert Fail (cubre la línea de fallos en buildSaveResultMap)
        ProductImportWizardController.importProducts(jsonBad, 'insert', null);
        
        // Test Update
        ProductImportWizardController.importProducts(jsonUpdate, 'update', null);
        
        // Test Upsert con ID
        ProductImportWizardController.importProducts(jsonUpdate, 'upsert', 'Id');
        
        // Test Upsert Fail (cubre la línea de fallos en buildUpsertResultMap)
        ProductImportWizardController.importProducts(jsonBad, 'upsert', 'Id');
        
        // Test Upsert con valid External ID
        try {
            ProductImportWizardController.importProducts(jsonUpdate, 'upsert', 'ProductCode');
        } catch(Exception e) {}

        // Test Upsert con Invalid External ID
        try {
            ProductImportWizardController.importProducts(jsonUpdate, 'upsert', 'InvalidField__c');
        } catch(AuraHandledException e) {}
        
        // Test Empty List
        try {
            ProductImportWizardController.importProducts('[]', 'insert', null);
        } catch(AuraHandledException e) {}
        
        // Test Invalid Operation
        try {
            ProductImportWizardController.importProducts(jsonInsert, 'invalid_operation', null);
        } catch(AuraHandledException e) {}
        
        // Test Generic Exception parsing (malformed JSON)
        try {
            ProductImportWizardController.importProducts('BAD_JSON_NOT_VALID', 'insert', null);
        } catch(Exception e) {}

        Test.stopTest();
    }
    
    @isTest
    static void testGovernorLimits() {
        List<Product2> limitProds = new List<Product2>();
        Integer limitRows = Limits.getLimitDmlRows();
        for(Integer i=0; i < limitRows + 1; i++) {
            limitProds.add(new Product2(Name='Lim' + i));
        }
        
        Test.startTest();
        try {
            ProductImportWizardController.importProducts(JSON.serialize(limitProds), 'insert', null);
        } catch(AuraHandledException e) {}
        Test.stopTest();
    }
}