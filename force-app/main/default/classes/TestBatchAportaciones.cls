@isTest
private class TestBatchAportaciones
{

   @isTest static void testBatch()
   {
      TestUtil tu = new TestUtil();
      tu.initPedidoReporteAportacion();

      Test.startTest();
      BatchAportaciones batch = new BatchAportaciones();
      Id batchId = Database.executeBatch(batch);
      Test.stopTest();
   }
	
}