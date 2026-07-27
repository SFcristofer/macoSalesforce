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
    static void testImportProducts() {
        Product2 existingProd = [SELECT Id FROM Product2 WHERE RecordType.DeveloperName = 'Producto' LIMIT 1];
        Id baseRtId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Producto').getRecordTypeId();
        
        List<Product2> toInsert = new List<Product2>{
            new Product2(RecordTypeId=baseRtId, Name='WizTest', IsActive=false, Family='B-!DEA Heating & Fan', Subfamilia__c='1-Fans', Clase__c='01-Stand & Tower Fans', Marca__c='A-!DEA Garden')
        };
        List<Product2> toUpdate = new List<Product2>{
            new Product2(Id=existingProd.Id, Name='WizUpdate')
        };
        
        String jsonInsert = JSON.serialize(toInsert);
        String jsonUpdate = JSON.serialize(toUpdate);
        
        Test.startTest();
        
        // Test Insert
        Map<String, Object> resInsert = ProductImportWizardController.importProducts(jsonInsert, 'insert', null);
        
        // Test Update
        Map<String, Object> resUpdate = ProductImportWizardController.importProducts(jsonUpdate, 'update', null);
        
        // Test Upsert
        Map<String, Object> resUpsert = ProductImportWizardController.importProducts(jsonUpdate, 'upsert', 'Id');
        
        // Test Exceptions
        try {
            ProductImportWizardController.importProducts('[]', 'insert', null);
        } catch(AuraHandledException e) {}
        
        try {
            ProductImportWizardController.importProducts(jsonInsert, 'invalid', null);
        } catch(AuraHandledException e) {}
        
        try {
            ProductImportWizardController.importProducts(jsonUpdate, 'upsert', 'InvalidFieldDoesNotExist__c');
        } catch(AuraHandledException e) {}
        
        // Test Governor Limit
        List<Product2> manyProds = new List<Product2>();
        for(Integer i=0; i< 10001; i++){
            manyProds.add(new Product2(Name='Test'));
        }
        try {
            ProductImportWizardController.importProducts(JSON.serialize(manyProds), 'insert', null);
        } catch(AuraHandledException e) {}
        
        // Test DML Failure
        List<Product2> failInsert = new List<Product2>{ new Product2() }; // Empty product, should fail
        ProductImportWizardController.importProducts(JSON.serialize(failInsert), 'insert', null);
        ProductImportWizardController.importProducts(JSON.serialize(failInsert), 'upsert', 'Id');
        
        Test.stopTest();
    }
}
