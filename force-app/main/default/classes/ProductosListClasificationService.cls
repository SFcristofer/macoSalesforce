@RestResource(urlMapping='/products/listclasification/*')
global with sharing class ProductosListClasificationService {

    @HttpGet
    global static String doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        List<ProductListClassificationData> listProductsQuantity;
        Poduct_Services_LOG__c productServiceLOG;
        
        Map<String, String> httpParams;
        String httpMethod;
        String requestUri;
        String resourcePath;
        String remoteAddress;
        String jsonResult;
        String result;
        List<String> validIPAddress;
        
        httpMethod = req.httpMethod;
        httpParams = req.params;
        requestUri = req.requestURI;
        resourcePath = req.resourcePath;
        remoteAddress = req.remoteAddress;
        
        validIPAddress = DAOService.getMetadataProductService('ProdService');
        
        System.debug('method [' + httpMethod + ']');
        System.debug('params [' + httpParams + ']');
        System.debug('res uri [' + requestUri + ']');
        System.debug('res path [' + resourcePath + ']');
        System.debug('remote address [' + remoteAddress + ']');

        if(validIPAddress.isEmpty()) {
            result = '{"response":"ERROR", "desc": "Contact Administrator. Not configured IP data"}';
            saveLOG(remoteAddress, result, requestUri, httpParams);
            return result;
        }
        
        if(!validIPAddress.contains(remoteAddress)) {
            result = '{"response":"ERROR", "desc": "Not allowed access"}';
            saveLOG(remoteAddress, result, requestUri, httpParams);
            return result;
        }

        listProductsQuantity = DAOService.fetchProductsQuantity();
        jsonResult = JSON.serialize(listProductsQuantity);
        
        result = 'OK';
        saveLOG(remoteAddress, result, requestUri, httpParams);        
        
        return jsonResult;
    }
    
    
    private static void saveLOG(String premoteAddress, String presult, String prequestUri, Map<String, String> phttpParams) {
        String resultLog; 
        Poduct_Services_LOG__c productServiceLOG;

        productServiceLOG = new Poduct_Services_LOG__c();
        productServiceLOG.Fecha_Peticion__c = Datetime.now();
        productServiceLOG.Name = 'PSERVLISTCLASS';
        productServiceLOG.Remote_Address__c = premoteAddress;
        if(presult != null) {
            if(presult.contains('ERROR')) {
                if (presult.length() > 149) {
                    resultLog = presult.substring(1, 148);
                } else {
                    resultLog = presult;
                }
            }
            if(!presult.contains('ERROR')) {
                resultLog = 'OK';
            }
        }
        productServiceLOG.Response__c = resultLog;
        productServiceLOG.URI__c = prequestUri;
        productServiceLOG.URL_Params__c = String.valueOf(phttpParams);
        
        insert productServiceLOG;    
    }
    
    
}