/**
 * This class send a set of provider records to Libra
 * It class should be executed from console, since it is not called from 
 * support classes.
 * 
 * Use mode: This send two providers to Libra only for 200 partnership code
 * List<String> ids = new List<String>();
 * ids.add('123');
 * ids.add('456');
 * LibraSimpleAltaProveedor lsap = new LibraSimpleAltaProveedor(ids, '200');
 * lsap.execute();
 * 
 */
public class LibraSimpleAltaProveedor {
    private List<String> proveedorIds;
    //200,400,...
    private String validSociedad;

    public LibraSimpleAltaProveedor(List<String> pproveedorIds, String psociedad) {
        proveedorIds = pproveedorIds;
        validSociedad = psociedad;
    }

    public void execute() {
        List<Account> proveedores;
        List<AccountBatchLibra> proveedoresToLibra = new List<AccountBatchLibra>();
        Set<Account> updateResponse = new Set<Account>();
        List<Account> updateResponseList = new List<Account>();
        LibraAltaProveedorCallout altaProveedorCall;
        String sociedadesStr = '';
        String sociedadesStrDiff = '';
        String[] tokens;
        Integer consecutivoCS;
        String codigoRapido = '';
        String strConsecutivo;
        Incremento_CS__c increaseCS;
        String response;
        LibraCalloutResponse lcrAltaProveedor;
        JSON_LOG__c jsonLog;

        List<Sociedades__mdt> sociedades = DOBrandsDAO.getSociedades('USD');
        List<JSON_LOG__c> listJSONLog = new List<JSON_LOG__c>();

        proveedores = [SELECT Id, 
                              Name,
                              Codigo_pais2__c,
                              RazonSocial__c,
                              NroIdFiscal__c,
                              Registro_Libra_Sociedades__c,
                              CurrencyIsoCode,
                              BillingStreet,
                              BillingCity,
                              BillingPostalCode,
                              RecordTypeId,
                              RecordType.Name
                         FROM Account
                        WHERE RecordType.DeveloperName = 'Proveedor'
                          AND Id IN :proveedorIds
                          AND Name != null 
                          AND Codigo_pais2__c != null 
                          AND RazonSocial__c != null
                          AND NroIdFiscal__c != null
                          AND Registrar_Libra__c = true];

        increaseCS = getIncrement('proveedorLibra');
        consecutivoCS = (Integer)increaseCS.consecutive__c;
        consecutivoCS = consecutivoCS + 1;
        
        String sociedadIdentifier;        
        for(Sociedades__mdt soc : sociedades) {
            sociedadIdentifier = String.valueOf(soc.Identificador_Sociedad__c);            
            if(sociedadIdentifier.equals(validSociedad)) {
                sociedadesStr = sociedadesStr + soc.Identificador_Sociedad__c + ';';
            }
        }

        sociedadesStr = sociedadesStr.substring(0, sociedadesStr.length() - 1);
        
        System.debug('sociedadesStr [' + sociedadesStr + ']');
        
        for(Account proveedor : proveedores) {
            if(proveedor.Registro_Libra_Sociedades__c == null) {
               proveedor.Registro_Libra_Sociedades__c = '';
            }
            if(!proveedor.Registro_Libra_Sociedades__c.equals(sociedadesStr)) {
                sociedadesStrDiff = proveedor.Registro_Libra_Sociedades__c.difference(sociedadesStr);
                tokens = sociedadesStrDiff.split(';');
                strConsecutivo = String.valueOf(consecutivoCS);
                codigoRapido = increaseCS.prefix__c + strConsecutivo.leftPad(5, '0');
                proveedor.Codigo_rapido__c = codigoRapido;
                for(String token : tokens) {
                    proveedoresToLibra.add(new AccountBatchLibra(proveedor, token, codigoRapido, strConsecutivo));
                }
            }
            consecutivoCS = consecutivoCS + 1;
        }
        
        for(AccountBatchLibra abl : proveedoresToLibra) {
            altaProveedorCall = new LibraAltaProveedorCallout('produccionProveedores');
            lcrAltaProveedor = altaProveedorCall.executeCallout(abl);
        
            jsonLog = new JSON_LOG__c();
            jsonLog.name = 'libraAltaProveedor';
            jsonLog.endpoint__c = lcrAltaProveedor.endpoint;
            jsonLog.Fecha_Envio__c = Datetime.now();
            jsonLog.json__c = lcrAltaProveedor.request;
            jsonLog.Response_JSON__c = lcrAltaProveedor.response;
            listJSONLog.add(jsonLog);
        
            response = processResponse(lcrAltaProveedor.response);
        
            if(response.equals('OK')) {
                abl.account.Registro_Libra_Sociedades__c = sociedadesStr;
                updateResponse.add(abl.account);
            } else {
                System.debug('Res error[' + response + ']');
            }
        }
        
        insert listJSONLog;
        System.debug('listJSONLog.size[' + listJSONLog.size() + ']');
        
        System.debug('size update[' + updateResponse.size() + ']');
        if(updateResponse.size() > 0) {
            increaseCS.consecutive__c = consecutivoCS - 1;
            update increaseCS;
        
            updateResponseList = new List<Account>(updateResponse);
            update updateResponseList;
        }
        
    }

    public String processResponse(String response) {
        LibraStatusResponse resultAltaCliente;
        System.debug('CALL P RESULT[' + response + ']');
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