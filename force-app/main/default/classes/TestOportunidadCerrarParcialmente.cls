@isTest
private class TestOportunidadCerrarParcialmente {
	
	@isTest static void testOportunidadCerrarParcialmente(){
	    Opportunity opportunity;
        TestUtil tu = new TestUtil();
	    tu.initOpportunitySplit();
	    opportunity = tu.getOpportunity();

        test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);
        OportunidadCerrarParcialmente  ocp = new OportunidadCerrarParcialmente(sc);
	    ocp.saveChanges();
        test.stopTest();
	}
	
	
}