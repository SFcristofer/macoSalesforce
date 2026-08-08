@isTest
private class TestReporteMargenDetail 
{
    
    @isTest static void testReporteMargenDetail()
    {
      Opportunity myOpp;
      TestUtil tu = new TestUtil();
      tu.initPedidoReporte();
      myOpp = tu.getOpportunity();

      myOpp.StageName = 'Cerrada/Ganada';
      myOpp.Seguimiento_de_Reposici_n__c = 'No';
      myOpp.Is_Split_Flag__c = true;
      upsert myOpp;

      test.startTest();
      ReporteMargenDetail rmd = new ReporteMargenDetail();
      test.stopTest();      
    }
    

    @isTest static void testClienteContactoMargen() 
    {
        List<ClienteContactoMargen> ccmList = new List<ClienteContactoMargen>();
        Account ac1 = new Account(Name = 'ClienteContactoUno',
                                Estado__c = 'Activo',
                                PorcentajeAportaciones__c = 25,
                                PorcentajeConvenio__c = 30,
                                PlazoPago__c = '30',
                                BillingCountry = 'China',
                                Id_Externo__c = 'CE-01');

       Account ac2 = new Account(Name = 'ClienteContactoDos',
                                Estado__c = 'Activo',
                                PorcentajeAportaciones__c = 25,
                                PorcentajeConvenio__c = 30,
                                PlazoPago__c = '30',
                                BillingCountry = 'Italia',
                                Id_Externo__c = 'CE-02'); 

       Account ac3 = new Account(Name = 'ClienteContactoDos',
                                Estado__c = 'Activo',
                                PorcentajeAportaciones__c = 25,
                                PorcentajeConvenio__c = 30,
                                PlazoPago__c = '30',
                                Id_Externo__c = 'CE-02'); 

        ClienteContactoMargen  ccm1 = new ClienteContactoMargen(ac1);
        ClienteContactoMargen  ccm2 = new ClienteContactoMargen(ac2);
        ClienteContactoMargen  ccm3 = new ClienteContactoMargen(ac3);

        ccmList.add(ccm1);
        ccmList.add(ccm2);
        ccmList.add(ccm3);
        ccmList.sort();
    }   
}