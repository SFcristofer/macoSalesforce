public class RESTCall 
{
	public RESTCall() 
	{
		
	}

	public static String restCall(String endPoint, String httpMethod, Map<String, String> headers, String body)
	{
        String keyValue = null;
        String strResponse;
        
        HttpRequest req = null;
        Http http = null;
        HTTPResponse res;
        
        req = new HttpRequest();
        req.setMethod(httpMethod);//PUT
 
        for (String key : headers.keySet())
        {
            keyValue = headers.get(key);
            System.debug('key [' + key + '] value[' + keyValue + ']');
            req.setHeader(key, keyValue);
        }
        
        req.setEndpoint(endPoint);

        System.debug('BODY [' + body + ']');
        req.setBody(body);
        req.setTimeout(60000); 

        try 
        {
            http = new Http();
            res = http.send(req);
            
            System.debug(res.toString());
            strResponse = res.getBody();
            System.debug(strResponse);
            System.debug('STATUS:'+res.getStatus());
            System.debug('STATUS_CODE:'+res.getStatusCode());
        } 
        catch(System.CalloutException e) 
        {
            System.debug('exception: ' + e.getMessage());
        }
        
        return strResponse;

	}
}