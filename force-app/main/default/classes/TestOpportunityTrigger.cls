@isTest
private class TestOpportunityTrigger {
    
    @isTest static void testOpportunity() {
        System.debug('TEST OPPORTUNITY TRIGGER');
        test.startTest();
        Opportunity opp;
        TestUtil tu = new TestUtil();
        //tu.initOpportunityTestTotalPrice();

        tu.initOpportunitySplitTr();
        System.debug('INIT TOP XYZ');
        test.stopTest();
        opp = tu.getOpportunity();
        opp.Seguimiento_de_Reposici_n__c = 'Si';
        opp.Fecha_seguimiento_Reposicion__c = Date.today();
        opp.StageName = 'Cerrada/Ganada';
        //opp.Is_Split_Flag__c = false;
        System.debug('oppId [' + opp.Id + '] opp amount[' + opp.Amount + '] [' + opp.Is_Split_Flag__c + ']');

        System.debug('updating opp [' + opp.Id + ']');
        update opp;
        
        List<OpportunityLineItem> olis = [SELECT Id, Name, Quantity FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        for(OpportunityLineItem oli : olis) {
            System.debug('oliId[' + oli.Id + '] oliname[' + oli.Name + '] qty[' + oli.Quantity + ']');
        }
        /*try {
           System.debug('updating opp [' + opp.Id + ']');
           update opp;
        } catch (Exception e) {
           System.Assert(e.getMessage().contains('use boton <cerrar parcialmente>'));
        }*/

    }

}