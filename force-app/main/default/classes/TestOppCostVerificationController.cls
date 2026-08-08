@isTest
private class TestOppCostVerificationController {

    @isTest static void testOppController() {

        Opportunity opportunity;
        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        opportunity = tu.getOpportunity();
 
        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);
        OppCostVerificationController  ocp = new OppCostVerificationController(sc);

        for(ProductCostVerification pcv : ocp.prods) {
            pcv.isMarkedForVerification = true;
        }

        ocp.verification();
        ocp.manualVerification();        
     }
 

}