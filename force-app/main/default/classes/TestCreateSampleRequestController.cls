@isTest
private class TestCreateSampleRequestController {
    
    @isTest static void testSampleRequest() {
        /*TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        CreateSampleRequestController csrc = new CreateSampleRequestController(
                                                    new ApexPages.StandardController(
                                                            tu.getOpportunity()));
        csrc.samples[0].selected = true;
        csrc.samples[1].selected = true;
        csrc.insertSampleRequest();

        list<Solicitud_de_Muestra__c> ls = tu.getSolicitudesDeMuestra();
        system.assertEquals(ls.size(), 1);
        system.assertEquals(tu.getMuestras(ls[0]).size(), 2);*/
    }

    @isTest static void testMNPRequest() {
        /*TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        CreateSampleRequestController csrc = new CreateSampleRequestController(
                                                    new ApexPages.StandardController(
                                                            tu.getOpportunity()));
        
        csrc.samples[0].selected = false;
        csrc.samples[1].selected = false;
        csrc.muestrasNP[0].selected = true;
        csrc.muestrasNP[0].tipoMuestra = 'Full sample';
        csrc.insertSampleRequest();

        list<Solicitud_de_Muestra__c> ls = tu.getSolicitudesDeMuestra();
        system.assertEquals(ls.size(), 1);
        system.assertEquals(tu.getMuestras(ls[0]).size(), 1);*/
    }
    
    
}