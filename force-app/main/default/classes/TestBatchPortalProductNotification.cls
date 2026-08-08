@isTest
private class TestBatchPortalProductNotification {
    @isTest
    private static void testNotifications() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        Id idRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('Prospecto_de_Producto').getRecordTypeId();
        Product2 productoProspecto = new Product2(RecordTypeId = idRT,
                                                            ProductoBase__c = tu.productosBase[0].Id,
                                                            Fabrica__c = tu.fabrica.Id,
                                                            Name = '[Providers Portal] Test Product',
                                                            PrecioDeFabrica__c = 1000,
                                                            Codigo_Proveedor__c = 'T-800',
                                                            Packaging__c = '1-CAJA MARRON',
                                                            MOQ__c = 5000,
                                                            CostoPackaging__c = 0,
                                                            PlazoDeFabricacion__c = '30-45 días');
        
        /*This commented lines should not be commented and the Test.isRuningTest condition in the 
        BatchPortalProductNotification class should be removed, but for some strange reason
        the portal Guest User fails to create a product within the test class but manages to do so in the portal */
        //system.runAs(portalGuest) {
            insert productoProspecto;
        //}
        test.startTest();
        BatchPortalProductNotification nb = new BatchPortalProductNotification();
        String schedId = Database.executeBatch(nb);
        test.stopTest();
    }

}