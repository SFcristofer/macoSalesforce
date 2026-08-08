@isTest
private class TestBatchSolicitudes 
{

   @isTest static void testBatch()
   {
      TestUtil tu = new TestUtil();
      tu.initOpportunityTest();	   
      Test.startTest();
      tu.initPedidoAgente();

      BatchPedidosConfirmados batch = new BatchPedidosConfirmados('DEPOSITO');
      Id batchId = Database.executeBatch(batch);
      Test.stopTest();
   }
	
}