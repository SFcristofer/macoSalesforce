/**
*    Uses Google Translate to translate Spanish into English
*    @author lcosta@infolastic.com
*    @version 1.0
*/

public class TranslationService{
    public String translation {get;set;}
    private static String T_URL = 'https://translate.googleapis.com/translate_a/single?client=gtx'
                                    + '&sl=es&tl=en&dt=t&q=';
    public static String translate(String esText){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(T_URL + esText.replace(' ', '%20'));
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return getTextByNodeId(res.getBody());
    }
    
    private static String getTextByNodeId(String xmlSource){
        JSONParser parser = JSON.createParser(xmlSource);
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
        parser.nextToken();
        return parser.getText();
    }
}