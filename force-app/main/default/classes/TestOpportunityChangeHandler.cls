@isTest
private class TestOpportunityChangeHandler {
	@isTest static void testHandler() {

        PlanificacionComercial__c plcom;
        Opportunity opportunity;
        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        opportunity = tu.getOpportunity();
        plcom = tu.getPlanificacionComercial();        

        OpportunityChangeHandler och = new OpportunityChangeHandler();
        och.cloneOpportunityFromData(opportunity.Id, plcom.Id, 'Test1');
     }
}