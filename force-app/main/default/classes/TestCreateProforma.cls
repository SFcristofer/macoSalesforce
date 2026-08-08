@isTest
public class TestCreateProforma {
    
    @isTest
    public static void TestCreateProforma() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();
        EstudioOportunidad__c eo = [SELECT Id FROM EstudioOportunidad__c LIMIT 1];
        CreateProforma cp = new CreateProforma(new ApexPages.StandardController(eo));
        cp.createProformaAndRedirect();
    }
}