public abstract class LibraCallout 
{
    protected Map<String, String> httpHeaders;  
    public static String CS_USER;
    public static String CS_PASS;
    public static String CS_ALIAS;
    public static String CS_ENDPOINT;
    public static String PARAM_USER;
    public static String PARAM_PWD;
    public static String PARAM_ALIAS;

    public LibraCallout(String type) 
    {
        LibraWS__c settings =  LibraWS__c.getValues(type);
        CS_USER = settings.param_id_user__c;
        CS_PASS = settings.param_pwd__c;
        CS_ALIAS = settings.param_alias__c;
        CS_ENDPOINT =settings.endpoint__c;

        System.debug('user[' + CS_USER + '] pwd[' + CS_PASS + '] alias[' + CS_ALIAS + '] endpnt[' + CS_ENDPOINT + ']');

        httpHeaders  = new Map<String, String>();
        httpHeaders.put('Content-Type', 'application/json');
        httpHeaders.put('Accept', 'application/json');

        PARAM_USER = 'idUser';
        PARAM_PWD = 'password';
        PARAM_ALIAS = 'alias';
    }

    
    private String callout(String httpMethod, String endpoint, Map<String, String> headers, String body)
    {
        String result;
        System.debug('CALL httmethod[' + httpMethod + '] headers[' + headers + ']');
        result = RestCall.restCall(endpoint, httpMethod, headers, body);
        return result;
    }

    //@Future
    public LibraCalloutResponse executeCallout(Object param) {
        LibraCalloutResponse lcr;
        Object objResponse;
        String response;
        String jsonPayload;
        String endpoint;
        lcr = new LibraCalloutResponse();

        jsonPayload = buildPayload(param);
        lcr.request = jsonPayload;

        endpoint = buildEndpoint();
        lcr.endpoint = endpoint;
        System.debug('endpoint[' + endpoint + ']');
        System.debug('payload[' + jsonPayload + ']');   
        response = callout('POST', endpoint, httpHeaders, jsonPayload);
        //response = '{\"status\" : \"OK\"}';
        //response = '{\"status\":\"ERROR\", \"errors\":{\"error_message\":\"El proveedor PR45 ya existe en la base de datos\"}}';

        objResponse = processResponse(response);
        lcr.responseObject = objResponse;
        lcr.response = response;

        return lcr;
    }

    public abstract String buildPayload(Object param);

    public abstract String buildEndpoint();

    public abstract Object processResponse(String response);
}