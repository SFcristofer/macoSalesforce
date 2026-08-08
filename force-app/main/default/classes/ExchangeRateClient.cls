/*
 * This class is a client to get the exchange rate from European Central Bank
 * https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml
 */
public class ExchangeRateClient {

    private static ExchangeRateClient INSTANCE;

    private ExchangeRateClient () {

    }

    public static ExchangeRateClient getInstance() {
        if(INSTANCE == null) {
          INSTANCE = new ExchangeRateClient();
        }
        return INSTANCE;
    }

    /**
     * @param endpoint. European Central Bank service endpoint
     * @param pcurrency. 'USD', 'JPY', etc
     */
    public void getExchangeRate(String endpoint, String pcurrency) {
        String response;

        //make a call
        executeCall(endPoint, pcurrency);
    }

    @future(callout=true)
    public static void executeCall(String endPoint, String pcurrency) {
        ExchangeRate er;
        String strResponse;
        HttpRequest req = null;
        Http http = null;
        HTTPResponse res;
        
        er = new ExchangeRate();
                
        req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endPoint);
        //https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml
        //https://es.exchange-rates.org/history/EUR/USD/T

        try {
            http = new Http();
            if(Test.isRunningTest()) {
               MockLibraHTTPResponseGenerator mock = new MockLibraHTTPResponseGenerator('exchangeRate');
               res = mock.respond(null);
            }
            else {
               res = http.send(req);
            } 
            System.debug(res.toString());
            strResponse = res.getBody();
            System.debug(strResponse);
            System.debug('STATUS:'+res.getStatus());
            System.debug('STATUS_CODE:'+res.getStatusCode());
        } catch(System.CalloutException e) {
            System.debug('Call Exception: ' + e.getMessage());
        }
        parseResponse(strResponse, er, pcurrency);
        System.debug('ExchangeRate [' + er.exchangeDate + '] [' + er.currencyRate + '] [' + er.rate + ']');
        saveData(er, pcurrency);
    }


    public static void parseResponse(String response, ExchangeRate er, String pcurrency) {
        Dom.Document dd = new Dom.Document();
        dd.load(response);
        Dom.XmlNode root = dd.getRootElement();
        System.debug('root name[' + root.getName() + ']');
        parse(root, er, pcurrency);
    }


    public static Boolean parse(Dom.XmlNode node, ExchangeRate er, String pcurrency) {
        System.debug('Parsing...');
        String attrKey;
        String attrVal;
        String rateAtt;
        String rateVal;
        Boolean retVal;

        Integer attrsCount = node.getAttributeCount();
        
        for(Integer i=0; i<attrsCount; i++){
            attrKey = node.getAttributeKeyAt(i);
            attrVal = node.getAttributeValue(attrKey,null);
            if(attrKey.equals('time')) {
                er.exchangeDate = attrVal;
            }
            if(attrKey.equals('currency') && attrVal.equals(pcurrency)) {
                er.currencyRate = attrVal;
                rateAtt = node.getAttributeKeyAt(i + 1);
                rateVal = node.getAttributeValue(rateAtt, null);
                er.rate = rateVal;
                return true;
            }
         }

        if(node.getNodeType() == Dom.XmlNodeType.ELEMENT) {   
            System.debug('Name[' + node.getName() + '] Type[' + node.getNodeType() + ']');
            Dom.XmlNode[] childs = node.getChildren();
            for(Dom.XmlNode child: childs) {
                retVal = parse(child, er, pcurrency);
                if(retVal) {
                    return true;
                }
            }
        } else if(node.getNodeType() == Dom.XmlNodeType.TEXT) {
            System.debug('Text[' + node.getText() + '] Type[' + node.getNodeType() + '] Name[' + node.getName() + ']');
            Dom.XmlNode[] childs = node.getChildren();
            for(Dom.XmlNode child: childs) {
                retVal = parse(child, er, pcurrency);
                if(retVal) {
                    return true;
                }
            }
        }
        return false;
    }


    public static void saveData(ExchangeRate exchngRate, String pcurrency) {
        Exchange_Rate__c xchngRate;
        String[] dateTokens;
        Date dateExchange;
        Decimal currencyToEuro;
        Decimal euroToCurrency;

        dateTokens = exchngRate.exchangeDate.split('-');
        if(dateTokens != null && dateTokens.size() == 3) {
            dateExchange = Date.newInstance(Integer.valueOf(dateTokens[0]), 
                                            Integer.valueOf(dateTokens[1]), 
                                            Integer.valueOf(dateTokens[2]));//yyyy,mm,dd
        }

        currencyToEuro = Decimal.valueOf(exchngRate.rate);
        euroToCurrency = 1 / currencyToEuro;
        
        xchngRate = new Exchange_Rate__c(Name = exchngRate.exchangeDate,
                                         Exchange_Date__c = dateExchange,
                                         Currency_Code__c = pcurrency,
                                         Rate__c = currencyToEuro,
                                         Rate_Euro_Currency__c = euroToCurrency);
        insert xchngRate;
    }


    class ExchangeRate {
        String exchangeDate {set; get;}
        String currencyRate {set; get;}
        String rate {set; get;}
    }

}