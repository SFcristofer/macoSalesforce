@isTest
private class TestCumplimiento {
    
    @isTest static void testBaseCumplimiento() {
        Integer anoReporte;
        TestUtil tu = new TestUtil();

        Ano_Reporte__mdt ano = [SELECT Ano__c
                                FROM Ano_Reporte__mdt
                                LIMIT 1];
        if(ano != null && ano.Ano__c != null){
            anoReporte = Integer.valueOf(ano.Ano__c);
        }


        tu.initOpportunityPedido(anoReporte);
        Opportunity o = tu.getOpportunity();
        o.Is_Split_Flag__c = true;
        System.debug('o.id [' + o.Id + ']');

        o.StageName = 'Cerrada/Ganada';
        o.Seguimiento_de_Reposici_n__c = 'No';
        update o;
        Cumplimiento c = new Cumplimiento();
        System.debug('avance [' + c.getAvance() + '] [' + c.getFalta() + '] [' + c.getObjetivoFormated().minifiedFig + ']');
        //system.assertEquals(c.getAvance(), 8003.2);
        //system.assertEquals(c.getFalta(), 1000000.0 - 8003.2);
        //system.assertEquals(c.getObjetivoFormated().minifiedFig, '1,0');
    }
    
}