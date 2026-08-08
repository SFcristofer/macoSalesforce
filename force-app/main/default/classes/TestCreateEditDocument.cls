@isTest
private class TestCreateEditDocument {
    
    @isTest static void testCreateDocument() {
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        test.startTest();
        PedidoDeCompra__c p = tu.createPedidoDeCompra(null);
        ApexPages.currentPage().getParameters().put('id', p.Id);

        CreateEditDocument ced = new CreateEditDocument();
        ced.newContents[0].fileBody = Blob.valueOf('Packing List');
        ced.newContents[0].fileName = 'Un archivo Importante';
        ced.saveChanges();
        test.stopTest();
    }
    
}