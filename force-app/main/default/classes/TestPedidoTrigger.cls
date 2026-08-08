@isTest
private class TestPedidoTrigger {
    
    /*Formerly only usert with 'T-800' alias was allowed to delete Pedido__c records
     * Now we are allowing anyone with the delete Pedido__c permission to do it 
    @isTest static void testDeletePedidoError() {
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        PedidoDeCompra__c pedido = tu.createPedidoDeCompra('volume');
        try{
            delete pedido;
        }catch(DMLException e){
            system.assertEquals('No se pueden eliminar Pedidos' , e.getDmlMessage(0));
        }   
    }
    */
   
    /** 
    *   Only users with T-800 as alias and ModifyAllData permission can delete Pedidos
    */
    @isTest static void testDeletePedidoTerminator() {
        TestUtil tu = new TestUtil();
        tu.initProformaTest();

        test.startTest();
        PedidoDeCompra__c pedido = tu.createPedidoDeCompra('volume');


        Profile p = [SELECT Id
                        FROM Profile
                        WHERE PermissionsModifyAllData = true
                        limit 1];
        User u = new User(Alias = 'T-800', 
                            Email='arnold@terminator.movie', 
                            EmailEncodingKey='UTF-8', 
                            LastName='Testing', 
                            LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', 
                            ProfileId = p.Id, 
                            TimeZoneSidKey='America/Los_Angeles', 
                            UserName='t-800@terminator.movie');
        

        System.runAs(u) {
            delete pedido;
        }
        test.stopTest();
    }
    
    @isTest static void testCreatePedidoProformaAutogenerado() {
        TestUtil tu = new TestUtil();
        tu.initProformaTest('Autogenerado');
        test.startTest();
        PedidoDeCompra__c pedido = tu.createPedidoDeCompra('volume');

        Profile p = [SELECT Id
                        FROM Profile
                        WHERE PermissionsModifyAllData = true
                        limit 1];
        User u = new User(Alias = 'T-800', 
                            Email='arnold@terminator.movie', 
                            EmailEncodingKey='UTF-8', 
                            LastName='Testing', 
                            LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', 
                            ProfileId = p.Id, 
                            TimeZoneSidKey='America/Los_Angeles', 
                            UserName='t-800@terminator.movie');
        

        System.runAs(u) {
            delete pedido;
        }
        test.stopTest();        
    }

    @isTest static void testUpdatePedido() {
        TestUtil tu = new TestUtil();
        tu.initProformaTest('Autogenerado');

        test.startTest();
        PedidoDeCompra__c pedido = tu.createPedidoDeCompra('volume');
        pedido.Name = 'testPedido';
        pedido.Estado2__c = 'EMBARCADO';

        //test.startTest();
        update pedido;
        test.stopTest();
    }


    @isTest static void testUpdatePedidoAportacion() {
        Decimal importe;
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();

        test.startTest();
        PedidoDeCompra__c pedido = tu.getPedido1();
        pedido.Estado2__c = 'EMBARCADO';

        update pedido;

        List<ProgramacionDeAportaciones__c> aportaciones;
        aportaciones = [SELECT Id, 
                               Name,
                               Importe__c,
                               Pedido_de_Compra__c
                          FROM ProgramacionDeAportaciones__c
                         WHERE Pedido_de_Compra__c = :pedido.Id];

        for(ProgramacionDeAportaciones__c pa : aportaciones) {
            importe = pa.Importe__c;
            System.debug('pa [' + importe + '] [' + pa.Pedido_de_Compra__c + ']');
        }
        //System.assertEquals(importe, 469.0);

        test.stopTest();
    }


    @isTest static void testPedidoTHMethod() {
    
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();

        test.startTest();
        PedidoDeCompra__c pedido = tu.getPedido1();
        
        Blob blobPDF;
        blobPDF = Blob.valueOf('Unit.Test');
        
         RecordType rt;
         rt = DOBrandsDAO.getRecordType('Documentacion_Pedido', 'Documento__c');    
    
        PedidoTriggerHelper pth = new PedidoTriggerHelper();
        PedidoTriggerHelper.createFileBlob('Factura', '');
        PedidoTriggerHelper.createFileBlob('Packing', '');
        PedidoTriggerHelper.getEmailTemplate();
        
        pth.getCents(1.45);
        
        PedidoTriggerHelper.createDocument(blobPDF, 'test.txt', 'Factura', rt.Id, pedido.Id);
        PedidoTriggerHelper.createEmailFileAttachment('tets.txt', blobPDF);
        pth.getIdAgentePrederminado();
    }
}