@isTest
private class TestCancelInvoiceController {

    @isTest static void testSimpleAltaFactura() {
        PedidoDeCompra__c pedido;
        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        pedido = tu.getPedido1();
        pedido.Fecha_Factura__c = Date.today();
        upsert pedido;

        LibraWS__c libraWSCS = new LibraWS__c();
	    libraWSCS.Name = 'desarrolloProveedores';
        libraWSCS.endpoint__c = 'http://127.0.0.1';
        libraWSCS.param_alias__c = 'SF_PROVEEDORES';
        libraWSCS.param_id_user__c = 'EDISA';
        libraWSCS.param_pwd__c = 'EDISA';
        
        insert libraWSCS;

        List<String> idsOrder = new List<String>();
        idsOrder.add(pedido.Id);

        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('altaCuenta'));

        ApexPages.currentPage().getParameters().put('id', pedido.Id);
        CancelInvoiceController cic = new CancelInvoiceController(new ApexPages.StandardController(pedido));
        cic.genereateInvoiceToSend();
        cic.executeLibraCallout();

    }


}