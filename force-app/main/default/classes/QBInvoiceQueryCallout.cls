/**
 * QB Call - Query invoice
 */
public class QBInvoiceQueryCallout extends QBCallout {
    private String QB_RESOURCE_ACTION;

    /*
     * metadataName - Check QBRESTConfiguration__mdt
     */
    public QBInvoiceQueryCallout(String metadataName) {
        super(metadataName, QBCallout.HTTP_METHOD_GET);
        QB_RESOURCE_NAME = 'query';
        QB_RESOURCE_ACTION = 'query';
    }


    public override String buildPayload(Object param) {
        String payload = '';
        return payload;
    }


    /*
     * 'callout:testQBNC/v3/company/9341451964358547/query?query=<selectstatement>'
     * GET /v3/company/9341451964358547/query?query=<selectStatement>&minorversion=73
     * 
     */
    public override String buildEndpoint(Object param) {
        String endpoint;
        
        List<FacturaDeCliente__c> facturasClienteContabilizadas;
        List<String> idsFacturaClienteContabilizadas;        
        
        List<Object> params = new List<Object>();
        String formatedBaseQuery;
        String baseQuery;
        String invoiceIdsParam = '';
        String balanceParam = '\'0\'';
                
        baseQuery = 'SELECT%20Id,Balance,PrivateNote,CustomerRef%20FROM%20Invoice%20WHERE%20Id%20%49%4E%28{0}%29%20AND%20Balance={1}';
        
        if(param instanceof List<FacturaDeCliente__c>) {
            facturasClienteContabilizadas = (List<FacturaDeCliente__c>)param;
            for(FacturaDeCliente__c fcliente : facturasClienteContabilizadas) {
                invoiceIdsParam = invoiceIdsParam + '\'' + fcliente.IdQbo__c + '\',';
            }
        }

        if(param instanceof List<String>) {
            idsFacturaClienteContabilizadas = (List<String>)param;
            for(String idqbocustomer : idsFacturaClienteContabilizadas) {
                invoiceIdsParam = invoiceIdsParam + '\'' + idqbocustomer + '\',';
            }
        }
        
        invoiceIdsParam = invoiceIdsParam.substringBeforeLast(',');

        params.add(invoiceIdsParam);
        params.add(balanceParam);
        
        formatedBaseQuery = String.format(baseQuery, params);
        
        endpoint = SF_NAMEDC_SCHEMA + SF_NAMED_CREDENTIAL + QB_URI_CONTEXT + QB_COMPANY_ID + '/' + QB_RESOURCE_NAME + '?' + QB_RESOURCE_ACTION + '=' + formatedBaseQuery;
        return endpoint;
    }


    public override Object processResponse(String response) {
        QBInvoiceQueryResponse responseQB;
        System.debug('CALL RESULT[' + response + ']');

        if(response == null) {
            return 'error: QB bad response, please verify the log and contact to your administrator';
        }

        try {
            responseQB = (QBInvoiceQueryResponse)JSON.deserialize(response, QBInvoiceQueryResponse.class);
        } catch(JSONException je) {
            System.debug(je.getMessage());
            return 'error: QB bad response ' + je.getMessage() + '. Contact your administrator';
        }
        return responseQB;
    }
    
}