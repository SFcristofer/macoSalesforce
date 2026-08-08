@isTest
private class TestSplitOpportunity {
	
	@isTest static void testSplit() 
	{
	   Opportunity opportunity;
       TestUtil tu = new TestUtil();
	   tu.initOpportunitySplit();
	   opportunity = tu.getOpportunity();

	   SplitOpportunityController spopc = new SplitOpportunityController(opportunity.Id);
	   spopc.splitOpportunities();

	}
	
	
}