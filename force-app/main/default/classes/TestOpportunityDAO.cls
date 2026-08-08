@isTest
private class TestOpportunityDAO {

	@isTest static void testDAO() {

	   Opportunity opportunity;
       TestUtil tu = new TestUtil();
	   tu.initOpportunitySplit();
	   opportunity = tu.getOpportunity();

       OpportunityDAO.getClonedOpportunity(opportunity.Id);
	}
}