global class BatchPagosLibra implements Database.Batchable<sObject>, Database.AllowsCallouts {
    private Date iniDate;
    private Date finDate;

    global BatchPagosLibra() {
        setupDates();
    }
	
    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('BatchPagosLibra  -  iniDate[' + iniDate + '] endDate[' + finDate + ']');

        return Database.getQueryLocator([SELECT Id, 
                                                Name,
                                                Proforma__r.Cuenta__r.Parent.Sociedad__c,
                                                Numero_de_Factura_Proveedor__c,
                                                Proforma__r.Oportunidad__r.PlanificacionComercial__r.Fin__c,
                                                Proforma__r.Oportunidad__r.PlanificacionComercial__r.Inicio__c
                                           FROM PedidoDeCompra__c
                                          WHERE Numero_de_Factura_Proveedor__c != null
                                            AND Proforma__r.Oportunidad__r.PlanificacionComercial__r.Inicio__c >= :iniDate
                                            AND Proforma__r.Oportunidad__r.PlanificacionComercial__r.Fin__c <= :finDate]);
    }


    global void execute(Database.BatchableContext BC, List<PedidoDeCompra__c> pedidos) {

        JSON_LOG__c jsonLog;
        List<JSON_LOG__c> listJSONLog = new List<JSON_LOG__c>();
        LibraCalloutResponse lcrDoCore;
        LibraCalloutResponse lcrDoAmerica;

        LibraPagosCallout pagosLibra = new LibraPagosCallout('produccionPagos', '200');
        lcrDoCore = pagosLibra.executeCallout(pedidos);

        jsonLog = new JSON_LOG__c();
        jsonLog.name = 'libraPagoDoCore';
        jsonLog.endpoint__c = lcrDoCore.endpoint;
        jsonLog.Fecha_Envio__c = Datetime.now();
        jsonLog.json__c = lcrDoCore.request;
        jsonLog.Response_JSON__c = lcrDoCore.response;
        listJSONLog.add(jsonLog);

        LibraPagosCallout pagosLibraDA = new LibraPagosCallout('produccionPagos', '400');
        lcrDoAmerica = pagosLibraDA.executeCallout(pedidos);

        jsonLog = new JSON_LOG__c();
        jsonLog.name = 'libraPagoDoAmerica';
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