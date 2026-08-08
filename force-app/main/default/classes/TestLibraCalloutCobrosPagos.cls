@isTest
private class TestLibraCalloutCobrosPagos 
{

    @isTest static void testCobros() 
    {
       List<PedidoDeCompra__c> pedidos;
       PedidoDeCompra__c pedido;        
       TestUtil tu = new TestUtil();
       tu.initOpportunitySplit();
       pedido = tu.getPedido1();
       pedido.Numero_de_Factura__c = 'F19/342';
       upsert pedido;

       LibraWS__c libraWSCS = new LibraWS__c();
	   libraWSCS.Name = 'desarrolloCobros';
       libraWSCS.endpoint__c = 'http://127.0.0.1';
       libraWSCS.param_alias__c = 'SFORCE_FACTURAS_VENTA';
       libraWSCS.param_id_user__c = 'EDISA';
       libraWSCS.param_pwd__c = 'EDISA';
        
       insert libraWSCS;

       pedidos = new List<PedidoDeCompra__c>();
       pedidos.add(pedido);

       Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('cobros'));
       Test.startTest();
       LibraCobrosCallout callout = new LibraCobrosCallout('desarrolloCobros', '200');
       callout.executeCallout(pedidos);
       Test.stopTest();

    }

    @isTest static void testPagos() 
    {
       List<PedidoDeCompra__c> pedidos;
       PedidoDeCompra__c pedido;        
       TestUtil tu = new TestUtil();
       tu.initOpportunitySplit();
       pedido = tu.getPedido1();
       pedido.Numero_de_Factura_Proveedor__c = 'ABC0023';
       upsert pedido;

       LibraWS__c libraWSCS = new LibraWS__c();
	   libraWSCS.Name = 'desarrolloPagos';
       libraWSCS.endpoint__c = 'http://127.0.0.1';
       libraWSCS.param_alias__c = 'SFORCE_FACTURAS_VENTA';
       libraWSCS.param_id_user__c = 'EDISA';
       libraWSCS.param_pwd__c = 'EDISA';
        
       insert libraWSCS;

       pedidos = new List<PedidoDeCompra__c>();
       pedidos.add(pedido);

       Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('pagos'));
       Test.startTest();
       LibraPagosCallout callout = new LibraPagosCallout('desarrolloPagos', '200');
       callout.executeCallout(pedidos);
       Test.stopTest();

    }

}