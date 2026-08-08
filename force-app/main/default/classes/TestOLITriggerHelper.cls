@isTest
private class TestOLITriggerHelper {
    
    @isTest
    private static void TestLastPrice() {
        TestUtil tu = new TestUtil();
        tu.initProformaTest('Autogenerado');
        test.startTest();
        tu.proforma.ConfirmacionCliente__c = true;
        update tu.proforma;
        tu.opp.Seguimiento_de_Reposici_n__c = 'No';
        tu.opp.StageName = 'Cerrada/Ganada';
        update tu.opp;
        tu.createOpportunity(tu.clienteContacto, tu.pc);
        tu.createOpportunityLineItems(tu.opp, tu.customPB);
        test.stopTest();

    }

    @isTest
    private static void TestUpdatePrice() {
        TestUtil tu = new TestUtil();
        tu.initProformaTest('Autogenerado');
        test.startTest();
        tu.proforma.ConfirmacionCliente__c = true;
        update tu.proforma;
        tu.opp.Seguimiento_de_Reposici_n__c = 'No';
        tu.opp.StageName = 'Cerrada/Ganada';
        update tu.opp;
        OpportunityLineItem oli = [SELECT Id 
                                    FROM OpportunityLineItem
                                    LIMIT 1];
        oli.UnitPrice = 123;
        OLITriggerHelper.resetRunForTesting();
        update oli;
        OLITriggerHelper.resetRunForTesting();
        delete tu.opp;
        test.stopTest();

    }
}