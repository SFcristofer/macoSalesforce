@isTest
private class TestBoardMeetingAgenda {
    
    @TestSetup
    static void makeData(){
        Account a = new Account(Name = 'SORIANA - GRUPO');
        insert a;
        TestUtil tu = new TestUtil();
        Account sorianaChild = tu.createClienteContacto(a.Id);
        tu.createPlanificacionComercial(sorianaChild);
    }
    
    @isTest static void testPreviewBoardData() {
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        Informe_Direccion__c ig = new Informe_Direccion__c();
        insert ig;
        test.startTest();
        PreviewBoardMeetingAgenda pbma = new PreviewBoardMeetingAgenda(new ApexPages.StandardController(ig));
        test.stopTest();
    }

    @isTest static void testSendBoardMeetingAgenda() {
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        Informe_Direccion__c ig = new Informe_Direccion__c();
        ig.Enviar_a__c = 'test@test.com';
        insert ig;
        Test.startTest();
        SendBoardMeetingAgenda pbma = new SendBoardMeetingAgenda(new ApexPages.StandardController(ig));
        pbma.sendMail();
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
 
        System.assertEquals(1, invocations, 'An email has not been sent');
    }

    @isTest static void testBoardMeetingAgenda() {
        TestUtil tu = new TestUtil();
        tu.initProformaTest();
        Informe_Direccion__c ig = new Informe_Direccion__c();
        insert ig;
        Test.startTest();
        BoardMeetingAgenda bma = new BoardMeetingAgenda(new ApexPages.StandardController(ig));
        Test.stopTest();
 
    }
    
    
}