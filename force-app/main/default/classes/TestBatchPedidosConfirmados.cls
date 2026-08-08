@isTest
private class TestBatchPedidosConfirmados 
{
	
	@isTest static void testBatchPedidosDeposito() 
	{
        TestUtil tu = new TestUtil();
         tu.initOpportunityTest();   
         Test.startTest();
         tu.initPedidoAgente();

        BatchPedidosConfirmados batch = new BatchPedidosConfirmados('DEPOSITO');
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
	}

	@isTest static void testBatchPedidosBalance() 
	{
        TestUtil tu = new TestUtil();
         tu.initOpportunityTest();   
         Test.startTest();
        tu.initPedidoAgente();

        BatchPedidosConfirmados batch = new BatchPedidosConfirmados('REMANENTE');
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
	}

	@isTest static void testTrasferenciaSplit() 
	{
        PedidoTransferenciaSplit pt1 = new PedidoTransferenciaSplit();
		pt1.pedidoId = 'pe1';
	    pt1.pedidoName = 'pe1';
	    pt1.pedidoSociedad = 'pe1';
	    pt1.pedidoProveedor = 'pe1';
	    pt1.pedidoProveedorName = 'pe1';   


        PedidoTransferenciaSplit pt2 = new PedidoTransferenciaSplit();
		pt2.pedidoId = 'pe2';
	    pt2.pedidoName = 'pe2';
	    pt2.pedidoSociedad = 'pe2';
	    pt2.pedidoProveedor = 'pe2';
	    pt2.pedidoProveedorName = 'pe12';

		pt1.equals(pt2);

	}


}