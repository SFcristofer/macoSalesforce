@isTest
private class TestSolicitudTransferenciaController {
	
	@isTest static void testController() {
        List<PedidoTransferencia> ppedidosTransferencia = new List<PedidoTransferencia>();
        PedidoTransferencia pedidoTr;
        String idPedido;
        PedidoDeCompra__c pedido;
        SolicitudTransferenciaController stc;
        List<PedidoDeCompra__c> pedidosTest;
        List<PedidoDeCompra__c> pedidos;
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();	   
        test.startTest();
		tu.initPedidoAgente();
        pedidos = tu.getPedidosAgente();
        pedido = pedidos.get(0);
        idPedido = pedido.Id;
        pedido = [SELECT Id, 
                         Name,
                         CostoOrigen__c,
                         PorcentajeDepositoAFabrica__c,
                         Monto_deposito__c
                    FROM PedidoDeCompra__c
                   WHERE Id = :idPedido];

         pedidoTr = new PedidoTransferencia();
         pedidoTr.pedido = pedido;
         pedidoTr.importe = 50;
         pedidoTr.tipo = 'Depósito';
         pedidoTr.informacion = 'importe total';
         pedidoTr.selected = true;
         ppedidosTransferencia.add(pedidoTr);

         pedidoTr.compareTo(pedidoTr);

        stc = new SolicitudTransferenciaController();
        stc.pedidosTransferencia = ppedidosTransferencia;
        stc.selectTransfers();
        stc.aprobar();
        stc.calcularMontoDeposito(pedido);
        stc.calcularBalance(pedido);
        pedidosTest = stc.pedidos;
        Boolean tstBln  = stc.checkTest;
        test.stopTest();
    }
    
    @isTest static void testDepositApproval() {
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        tu.createPedidoDeCompraStatus('Embarcado');
        PedidoDeCompra__c testOrder = tu.getPedidos().get(0);
        
        system.assertEquals(null, testOrder.Fecha_Aprobacion_Pago_Deposito__c);
        
        //These sentencess overcome the necessity to add all the documents and conditions to the
        //Order for it to be picked up by the controller
        List<PedidoTransferencia> ppedidosTransferencia = new List<PedidoTransferencia>();
        PedidoTransferencia pedidoTr = new PedidoTransferencia();
        pedidoTr.pedido = testOrder;
        pedidoTr.importe = 50;
        pedidoTr.tipo = 'Depósito';
        pedidoTr.informacion = 'importe total';
        pedidoTr.selected = true;
        ppedidosTransferencia.add(pedidoTr);
        
        test.startTest();
        SolicitudTransferenciaController stc = new SolicitudTransferenciaController();
        stc.pedidosTransferencia = ppedidosTransferencia; //here we assign the mock data
        stc.selectTransfers();
        stc.aprobar();
        test.stopTest();
        testOrder = tu.getPedidos().get(0);
        system.assert(testOrder.Aprobada_Transferencia_Deposito__c, 'No se registro la aprobación del depósito');
        system.assertEquals(Date.today(), testOrder.Fecha_Aprobacion_Pago_Deposito__c, 'No se registro la fecha del depósito');
    }
    
    @isTest static void testBalanceApproval() {
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        tu.createPedidoDeCompraStatus('Embarcado');
        PedidoDeCompra__c testOrder = tu.getPedidos().get(0);
        
        system.assertEquals(null, testOrder.Fecha_Aprobacion_Pago_Deposito__c);
        
        //These sentencess overcome the necessity to add all the documents and conditions to the
        //Order for it to be picked up by the controller
        List<PedidoTransferencia> ppedidosTransferencia = new List<PedidoTransferencia>();
        PedidoTransferencia pedidoTr = new PedidoTransferencia();
        pedidoTr.pedido = testOrder;
        pedidoTr.importe = 450;
        pedidoTr.tipo = 'Balance';
        pedidoTr.informacion = 'importe total';
        pedidoTr.selected = true;
        ppedidosTransferencia.add(pedidoTr);
        
        test.startTest();
        SolicitudTransferenciaController stc = new SolicitudTransferenciaController();
        stc.pedidosTransferencia = ppedidosTransferencia; //here we assign the mock data
        stc.selectTransfers();
        stc.aprobar();
        test.stopTest();
        testOrder = tu.getPedidos().get(0);
        system.assert(testOrder.Aprobada_Transferencia_Balance__c, 'No se registro la aprobación del balance');
        system.assertEquals(Date.today(), testOrder.Fecha_Aprobacion_Pago_Balance__c, 'No se registro la fecha del balance');
	}
	
}