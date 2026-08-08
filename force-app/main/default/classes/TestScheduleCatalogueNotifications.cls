@isTest
private class TestScheduleCatalogueNotifications {
    @TestSetup
    static void makeData(){
        Id idRT = Schema.sObjectType.Account.getRecordTypeInfosByDeveloperName().get('ClienteContacto').getRecordTypeId();

        Account clienteContacto = new Account(RecordTypeId = idRT,
                                Name = 'ClienteContactoUno - cliente',
                                Estado__c = 'Activo',
                                PorcentajeAportaciones__c = 25,
                                EmailComercial__c = 'test@test.com',
                                PorcentajeConvenio__c = 30,
                                PlazoPago__c = '30',
                                BillingCountry = 'China',
                                Portal_Token__c = '123',
                                Id_Externo__c = 'CE-01',
                                Sociedad__c = 'Do América');
        insert clienteContacto;
        PlanificacionComercial__c pc = new PlanificacionComercial__c(Name = String.valueOf(Date.today().year()), 
                                           Cuenta__c = clienteContacto.Id,
                                           Activa__c = true,
                                           Inicio__c = Date.newInstance(Date.today().year(), 1, 1),
                                           Fin__c = Date.newInstance(Date.today().year(), 12, 31),
                                           PorcentajeAportaciones__c = 10,
                                           PorcentajeConvenio__c = 3,
                                           Objetivo_de_Margen__c = 50,
                                           ObjetivoDeVentas__c = 1000000);
        insert pc;
        Catalogo__c c = new Catalogo__c();
        insert c;
        Opportunity opp = new Opportunity(Name = 'Test Opportunity',
                                AccountId = clienteContacto.Id,
                                Is_Brand_Selected__c = true,
                                PlanificacionComercial__c = pc.Id,
                                CloseDate = Date.today(),
                                StageName = 'Toma de Contacto',
                                Campana__c = 'Back to School',
                                Fecha_de_Compromiso__c = Date.today(),
                                Catalogo__c = c.Id);
        insert opp;
    }

    @isTest
    private static void testNotifications() {
        test.startTest();
        BatchCatalogueNotifications sc = new BatchCatalogueNotifications();
        String schedId = System.scheduleBatch(sc, 'BatchCatNotif', 1);
        test.stopTest();
    }

}