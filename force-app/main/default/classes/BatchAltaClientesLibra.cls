global class BatchAltaClientesLibra implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {

        return Database.getQueryLocator([SELECT Id, 
                                                Name,
                                                Alta_Libra__c,
                                                Codigo_pais2__c,
                                                RazonSocial__c,
                                                NroIdFiscal__c,
                                                Registro_Libra_Sociedades__c,
                                                RecordTypeId,
                                                Codigo_rapido__c,
                                                CurrencyIsoCode,
                                                Sociedad__c,
                                                BillingStreet,
                                                BillingCity,
                                                BillingPostalCode,
                                                RecordType.Name
                                           FROM Account
                                          WHERE RecordType.DeveloperName = 'Cliente'
                                            AND Name != null 
                                            AND Codigo_pais2__c != null 
                                            AND RazonSocial__c != null 
                                            AND NroIdFiscal__c != null
                                            AND Sociedad__c != null
                                            AND Alta_Libra__c = false
                                            AND Registrar_Libra__c = true]);
    }

    global void execute(Database.BatchableContext BC, List<Account> clientes) {
        List<AccountBatchLibra> clientesToLibra = new List<AccountBatchLibra>();
        List<Account> updateResponse = new List<Account>();
        LibraAltaClienteCallout altaClienteCall;
        List<Sociedades__mdt> sociedades = DOBrandsDAO.getSociedades();
        Map<String, Sociedades__mdt> mapNameSociedad = new Map<String, Sociedades__mdt>();
        Sociedades__mdt sociedadMDT;
        Integer consecutivoCS;
        String codigoRapido = '';
        String strConsecutivo;
        Incremento_CS__c increaseCS;
        String response;

        JSON_LOG__c jsonLog;
        List<JSON_LOG__c> listJSONLog = new List<JSON_LOG__c>();
        LibraCalloutResponse lcrAltaCliente;

        increaseCS = getIncrement('clienteLibra');
        consecutivoCS = (Integer)increaseCS.consecutive__c;
        consecutivoCS = consecutivoCS + 1;

        System.debug('size soc [' + sociedades.size() + ']');

        for(Sociedades__mdt soc : sociedades) {
            mapNameSociedad.put(soc.Nombre__c, soc);
        }                

        for(Account cliente : clientes) {
            sociedadMDT = mapNameSociedad.get(cliente.Sociedad__c + ' ' + cliente.CurrencyIsoCode);
            if(sociedadMDT == null) {
                System.debug('Cliente ' + cliente.Name + ' cuya sociedad es [' + cliente.Sociedad__c + '] no esta resgitrada en MTD');
            }

            if(sociedadMDT != null) {
                strConsecutivo = String.valueOf(consecutivoCS);
                codigoRapido = 'CS' + strConsecutivo.leftPad(5, '0');
                cliente.Codigo_rapido__c = codigoRapido;
                clientesToLibra.add(new AccountBatchLibra(cliente, String.valueOf(sociedadMDT.Identificador_Sociedad__c), '', strConsecutivo));
                consecutivoCS = consecutivoCS + 1;
            }
        }

        System.debug('Clients to be selected to Libra[' + clientes.size()+ '] ins[' + clientesToLibra.size() + ']');

        for(AccountBatchLibra abl : clientesToLibra) {
            altaClienteCall = new LibraAltaClienteCallout('produccionClientes');
            lcrAltaCliente = altaClienteCall.executeCallout(abl);

            jsonLog = new JSON_LOG__c();
            jsonLog.name = 'libraAltaCliente';
            jsonLog.endpoint__c = lcrAltaCliente.endpoint;
            jsonLog.Fecha_Envio__c = Datetime.now();
            jsonLog.json__c = lcrAltaCliente.request;
            jsonLog.Response_JSON__c = lcrAltaCliente.response;
            listJSONLog.add(jsonLog);

            response = processResponse(lcrAltaCliente.response);
            if(response.equals('OK')) {
                abl.account.Alta_Libra__c = true;
                updateResponse.add(abl.account);
            } else {
                System.debug('Res error[' + response + ']');
            }
        }

        insert listJSONLog;

        System.debug('size update[' + updateResponse.size() + ']');
        if(updateResponse.size() > 0) {
            increaseCS.consecutive__c = consecutivoCS - 1;
            update increaseCS;
        }

        update updateResponse;
    }

    global void finish(Database.BatchableContext BC) {
        
    }

    public String processResponse(String response) {
        LibraStatusResponse resultAltaCliente;
        System.debug('CALL X RESULT[' + response + ']');
        String result = '';

        if(response == null) {
            response = '{"status":"ERROR", "errors":{"error_message":"Response from WS was NULL"}}';
        }

        try {
            resultAltaCliente = (LibraStatusResponse)JSON.deserialize(response, LibraStatusResponse.class);
            if(resultAltaCliente.status.equals('OK')) {
                result = 'OK';
            }
            if(resultAltaCliente.status.equals('ERROR')) {
               if(resultAltaCliente.errors != null) {
                    result = resultAltaCliente.errors.error_message;
               }
            }
        } catch(JSONException je) {
            result = response;
        }
        return result;
    }

    private Incremento_CS__c getIncrement(String name) {
        Incremento_CS__c increaseCS;

        // Obtener valores
        increaseCS = [SELECT Id, 
                             Name, 
                             prefix__c, 
                             year__c, 
                             consecutive__c 
                        FROM Incremento_CS__c
                       WHERE Name = :name];
        return increaseCS;
    }

}