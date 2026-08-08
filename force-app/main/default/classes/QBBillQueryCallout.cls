/**
 * QB Call - Query bill
 */
public class QBBillQueryCallout extends QBCallout {
    private String QB_RESOURCE_ACTION;
    public static final String QUERY_BALANCE = 'QBQBalance';
    public static final String QUERY_SYNCTOKEN = 'QBQSyncToken';
    private String typeQuery;

    /*
     * metadataName - Check QBRESTConfiguration__mdt
     */
    public QBBillQueryCallout(String metadataName, String ptquery) {
        super(metadataName, QBCallout.HTTP_METHOD_GET);
        QB_RESOURCE_NAME = 'query';
        QB_RESOURCE_ACTION = 'query';
        typeQuery = ptquery;
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
        List<FacturaDeProveedor__c> facturasProveedorContabilizadas;
        List<Object> params = new List<Object>();
        String formatedBaseQuery;
        String baseQuery;
        String billIdsParam = '';
        String balanceParam = '\'0\'';

        if(typeQuery.equals(QUERY_BALANCE)) {
            baseQuery = 'SELECT%20Id,Balance,PrivateNote,VendorRef,SyncToken%20FROM%20Bill%20WHERE%20Id%20%49%4E%28{0}%29%20AND%20Balance={1}';//balance
        }

        if(typeQuery.equals(QUERY_SYNCTOKEN)) {
            baseQuery = 'SELECT%20Id,Balance,PrivateNote,VendorRef,SyncToken%20FROM%20Bill%20WHERE%20Id%20%49%4E%28{0}%29';//synctoken
        }
        
        facturasProveedorContabilizadas = (List<FacturaDeProveedor__c>)param;
        for(FacturaDeProveedor__c fproveedor : facturasProveedorContabilizadas) {
            billIdsParam = billIdsParam + '\'' + fproveedor.IdQbo__c + '\',';
        }
        
        billIdsParam = billIdsParam.substringBeforeLast(',');

        params.add(billIdsParam);
        
        if(typeQuery.equals(QUERY_BALANCE)) {
            params.add(balanceParam);
        }
        
        formatedBaseQuery = String.format(baseQuery, params);
        
        endpoint = SF_NAMEDC_SCHEMA + SF_NAMED_CREDENTIAL + QB_URI_CONTEXT + QB_COMPANY_ID + '/' + QB_RESOURCE_NAME + '?' + QB_RESOURCE_ACTION + '=' + formatedBaseQuery;
        return endpoint;
    }


    public override Object processResponse(String response) {
        QBBillQueryResponse responseQB;
        System.debug('CALL RESULT[' + response + ']');

        if(response == null) {
            return 'error: QB bad response, please verify the log and contact to your administrator';
        }

        try {
            responseQB = (QBBillQueryResponse)JSON.deserialize(response, QBBillQueryResponse.class);
        } catch(JSONException je) {
            System.debug(je.getMessage());
            return 'error: QB bad response ' + je.getMessage() + '. Contact your administrator';
        }
        return responseQB;
    }

}