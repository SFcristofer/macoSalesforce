@isTest
private class TestSolicitudTransferenciaInternacional {
	
	@isTest static void testSolicitudTransferencia() {
      PedidoDeCompra__c pedido;
      String idPedido;
      String idProveedor;
      String sociedad;
      List<PedidoDeCompra__c> pedidos;
      TestUtil tu = new TestUtil();
      tu.initOpportunityTest();
      test.startTest();	   
      tu.initPedidoAgente();
      pedidos = tu.getPedidosAgente();

      idPedido = pedidos.get(0).Id;
      pedido = [SELECT Id, Proveedor__c, Proforma__r.Cuenta__r.Parent.Sociedad__c FROM PedidoDeCompra__c WHERE Id = :idPedido];
      idProveedor = pedido.Proveedor__c;
      System.debug('test order provid[' + idProveedor + ']');
      sociedad = pedido.Proforma__r.Cuenta__r.Parent.Sociedad__c;

       //System.currentPageReference().getParameters().put('id', pedidos.get(0).Id); //adelanto
	System.currentPageReference().getParameters().put('idProv', idProveedor); //adelanto
	System.currentPageReference().getParameters().put('soc', sociedad); //adelanto                  
      System.currentPageReference().getParameters().put('typeOrdr', 'remanente');
      SolicitudTransferenciaInternacional sti = new SolicitudTransferenciaInternacional();
      test.stopTest();

	}
	
	
}