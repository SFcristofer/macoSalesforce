@isTest
public class TestReporteAportaciones 
{
    @isTest static void testReporte() 
    {
       TestUtil tu = new TestUtil();
       //tu.initOpportunityTest();	
	   tu.initPedidoReporteAportacion();

       test.startTest();
       ReporteAportaciones rmc = new ReporteAportaciones();
       test.stopTest();
	}
}