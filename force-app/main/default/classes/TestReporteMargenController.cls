@isTest
private class TestReporteMargenController {
	
	@isTest static void testReporte() 
	{
      TestUtil tu = new TestUtil();
      tu.initOpportunityTest();	
	  test.startTest();
      tu.initPedidoAgente();   

      ReporteMargenController rmc = new ReporteMargenController();
      test.stopTest();

	}
	
	
}