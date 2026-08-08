@isTest
public class TestOpportunityAWSController {

    @isTest static void testAWS() {
        Opportunity opp;
        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        opp = tu.getOpportunity();
        Test.setMock(HttpCalloutMock.class, new MockLibraHTTPResponseGenerator('aws'));
        Test.startTest();

        System.debug('oppId [' + opp.Id + '] ');

        ApexPages.currentPage().getParameters().put('id', opp.Id);
        OpportunityAWSController oawsc = new OpportunityAWSController(new ApexPages.StandardController(opp));
        oawsc.generarJSONAWS();

        AWSOportunityResult awsRes = new AWSOportunityResult();
        awsRes.URL = 'http://tst.com';

        Test.stopTest();        
    }
}