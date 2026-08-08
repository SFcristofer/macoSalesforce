public abstract class QBCallout {
    public static final String HTTP_METHOD_POST = 'POST';
    public static final String HTTP_METHOD_GET = 'GET';    

    protected Map<String, String> httpHeaders;  
    public String QB_BILL_ACC_REF;
    public String QB_BILL_AP_ACC_REF;
    public String QB_JOURNAL_ACC_REF_CRED;
    public String QB_JOURNAL_ACC_REF_DEB;
    public String QB_ITEM_REF;
    public String QB_ITEM_ACC_REF;
    public String QB_COMPANY_ID;
    public String QB_MINOR_VERSION;
    public String QB_URI_CONTEXT;    
    public String SF_NAMEDC_SCHEMA;
    public String SF_NAMED_CREDENTIAL;
    
    public String HTTP_METHOD;

    public String QB_RESOURCE_NAME;    

    public QBCallout(String mdtName, String httMethod) {
        QBRESTConfiguration__mdt config =  QBDAO.fetchQBConfigMetadata(mdtName);
        QB_BILL_ACC_REF = config.QB_Bill_Account_Ref__c;
        QB_BILL_AP_ACC_REF = config.QB_Bill_AP_Acc_Ref__c;
        QB_JOURNAL_ACC_REF_CRED = config.QB_Journal_Acc_Ref_Credit__c;
        QB_JOURNAL_ACC_REF_DEB = config.QB_Journal_Acc_Ref_Debit__c;
        QB_ITEM_REF = config.QB_Item_Ref__c;
        QB_ITEM_ACC_REF = config.QB_Item_Account_Ref__c;
        QB_COMPANY_ID = config.QB_Company_ID__c;
        QB_MINOR_VERSION = config.QB_Minor_Version__c;
        QB_URI_CONTEXT = config.QB_URI_Context__c;
        SF_NAMED_CREDENTIAL = config.SF_Named_Credential__c;
        SF_NAMEDC_SCHEMA = config.SF_NC_URL_schema__c;
        HTTP_METHOD = httMethod;

        System.debug('QB Callout [' + QB_BILL_ACC_REF + '] [' + QB_BILL_AP_ACC_REF + '] [' + QB_ITEM_REF + '] [' + QB_ITEM_ACC_REF + '] qbCompanyId[' + QB_COMPANY_ID + '] qbMinorV[' + QB_MINOR_VERSION + '] uri context[' + QB_URI_CONTEXT + '] namedCred[' + SF_NAMED_CREDENTIAL + '] schema[' + SF_NAMEDC_SCHEMA+ '] httpM[' + HTTP_METHOD + ']');

        httpHeaders  = new Map<String, String>();
        httpHeaders.put('Content-Type', 'application/json');
        httpHeaders.put('Accept', 'application/json');
    }

    
    private String callout(String httpMethod, String endpoint, Map<String, String> headers, String body) {
        String result;
        System.debug('CALL httmethod[' + httpMethod + '] headers[' + headers + ']');
        result = QBRestCall.restCall(endpoint, httpMethod, headers, body);
        return result;
    }

    //@Future
    public QBCalloutResponse executeCallout(Object param) {
        QBCalloutResponse qbcr;
        Object objResponse;
        String response;
        String jsonPayload;
        String endpoint;
        qbcr = new QBCalloutResponse();

        jsonPayload = buildPayload(param);
        qbcr.request = jsonPayload;

        endpoint = buildEndpoint(param);
        qbcr.endpoint = endpoint;
        System.debug('endpoint[' + endpoint + ']');
        System.debug('payload[' + jsonPayload + ']');   
        //response = callout('POST', endpoint, httpHeaders, jsonPayload);
        response = callout(HTTP_METHOD, endpoint, httpHeaders, jsonPayload);
        //response = '{\"status\" : \"OK\"}';
        //response = '{\"status\":\"ERROR\", \"errors\":{\"error_message\":\"El proveedor PR45 ya existe en la base de datos\"}}';
        qbcr.response = response;
        objResponse = processResponse(response);
        qbcr.responseObject = objResponse;

        return qbcr;
    }

    public abstract String buildPayload(Object param);

    public abstract String buildEndpoint(Object param);

    public abstract Object processResponse(String response);
}