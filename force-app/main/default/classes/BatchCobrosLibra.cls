global class BatchCobrosLibra implements Database.Batchable<sObject>, Database.AllowsCallouts {
    private Date iniDate;
    private Date finDate;

    global BatchCobrosLibra() {
        setupDates();
    }
	
    global Database.QueryLocator start(Database.BatchableContext BC) {

        return Database.getQueryLocator([SELECT Id, 
                                                Name,
                                                Proforma__r.Cuenta__r.Parent.Sociedad__c,
                                                Numero_de_Factura__c,
                                                Proforma__r.Oportunidad__r.PlanificacionComercial__r.Fin__c,
                                                Proforma__r.Oportunidad__r.PlanificacionComercial__r.Inicio__c
                                           FROM PedidoDeCompra__c
                                          WHERE Numero_de_Factura__c != null
                                            AND Proforma__r.Oportunidad__r.PlanificacionComercial__r.Inicio__c >= :iniDate
                                            AND Proforma__r.Oportunidad__r.PlanificacionComercial__r.Fin__c <= :finDate]);
	}


    global void execute(Database.BatchableContext BC, List<PedidoDeCompra__c> pedidos) {

        JSON_LOG__c jsonLog;
        List<JSON_LOG__c> listJSONLog = new List<JSON_LOG__c>();
        LibraCalloutResponse lcrDoCore;
        LibraCalloutResponse lcrDoAmerica;

        LibraCobrosCallout cobrosLibraDC = new LibraCobrosCallout('produccionCobros', '200');
        lcrDoCore = cobrosLibraDC.executeCallout(pedidos);

        jsonLog = new JSON_LOG__c();
        jsonLog.name = 'libraCobroDoCore';
        jsonLog.endpoint__c = lcrDoCore.endpoint;
        jsonLog.Fecha_Envio__c = Datetime.now();
        jsonLog.json__c = lcrDoCore.request;
        jsonLog.Response_JSON__c = lcrDoCore.response;
        listJSONLog.add(jsonLog);

        LibraCobrosCallout cobrosLibraDA = new LibraCobrosCallout('produccionCobros', '400');
        lcrDoAmerica = cobrosLibraDA.executeCallout(pedidos);

        jsonLog = new JSON_LOG__c();
        jsonLog.name = 'libraCobroDoAmerica';
        jsonLog.endpoint__c = lcrDoAmerica.endpoint;
        jsonLog.Fecha_Envio__c = Datetime.now();
        jsonLog.json__c = lcrDoAmerica.request;
        jsonLog.Response_JSON__c = lcrDoAmerica.response;
        listJSONLog.add(jsonLog);

        insert listJSONLog;
    }
	
    global void finish(Database.BatchableContext BC) {
    }

    private void setupDates() {
        Date aux = Date.today();
	    iniDate = Date.newInstance(aux.year(), 1, 1);
	    finDate = Date.newInstance(aux.year(), 12, 31);
    }
	
}