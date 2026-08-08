@RestResource(urlMapping='/products/listbyfsc/*')
global with sharing class ProductosListByFSCServiceService {

    private static String HTTP_PARAM_FAMILY = 'fam';
    private static String HTTP_PARAM_SUBFAMILY = 'sfam';
    private static String HTTP_PARAM_CLASE = 'cls';
    private static String HTTP_PARAM_FROM = 'from';
    private static String HTTP_PARAM_TO = 'to';

    @HttpGet
    global static String doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        List<ProductListClassificationData> listProductsQuantity;
        ProductListClassificationData prodClassification;
        List<Product2> listProds;
        List<ProductServiceResponse> listProdResponse;
        ProductServiceResponse prodSResp;
        String result = '';
        
        Map<String, String> httpParams;
        String httpMethod;
        String requestUri;
        String resourcePath;
        String remoteAddress;
        Integer paramsSize;
        String paramValue;
        List<String> paramsValidationErros;
        String errorDesc = '';
        Boolean isParamFromProvided;
        Boolean isParamToProvided;
        String paramFamily;
        String paramSubFamily;
        String paramClase;
        String paramFrom;
        String paramTo;
        Integer paramFromInt;
        Integer paramToInt;
        Integer numProds;
        Integer soqlLimit;
        Integer soqlOffset;
        List<String> validIPAddress;
        String exceptionMsg;
        
        httpMethod = req.httpMethod;
        httpParams = req.params;
        requestUri = req.requestURI;
        resourcePath = req.resourcePath;
        remoteAddress = req.remoteAddress;
        
        validIPAddress = DAOService.getMetadataProductService('ProdService');
        exceptionMsg = '';
        
        paramsValidationErros = new List<String>();
        isParamFromProvided = false;
        isParamToProvided = false;
        
        System.debug('method [' + httpMethod + ']');
        System.debug('params [' + httpParams + ']');
        System.debug('res uri [' + requestUri + ']');
        System.debug('res path [' + resourcePath + ']');
        System.debug('remote address [' + remoteAddress + ']');

        if(validIPAddress.isEmpty()) {
            result = '{"response":"ERROR", "desc": "Contact Administrator. Not configured IP data"}';
            saveLOG(remoteAddress, result, requestUri, httpParams, exceptionMsg);
            return result;
        }
        
        if(!validIPAddress.contains(remoteAddress)) {
            result = '{"response":"ERROR", "desc": "Not allowed access"}';
            saveLOG(remoteAddress, result, requestUri, httpParams, exceptionMsg);
            return result;
        }

        for(String paramName : httpParams.keySet()) {
            paramValue = httpParams.get(paramName);
            System.debug('param[' + paramName + '] value[' + paramValue +']');
            
            if(paramName.equals(HTTP_PARAM_FAMILY)) {
                if(validateSizeParamValue(paramName, paramValue, paramsValidationErros, 32)) {
                    paramFamily = paramValue;
                }
            }
            if(paramName.equals(HTTP_PARAM_SUBFAMILY)) {
                if(validateSizeParamValue(paramName, paramValue, paramsValidationErros, 32)) {
                    paramSubFamily = paramValue;
                }
            }
            if(paramName.equals(HTTP_PARAM_CLASE)) {
                if(validateSizeParamValue(paramName, paramValue, paramsValidationErros, 40)) {
                    paramClase = paramValue;
                }
            }
            if(paramName.equals(HTTP_PARAM_FROM)) {
                isParamFromProvided = true;
                if(validatePositiveInteger(paramName, paramValue, paramsValidationErros, 5)) {
                    paramFrom = paramValue;
                }
            }
            if(paramName.equals(HTTP_PARAM_TO)) {
                isParamToProvided = true;
                if(validatePositiveInteger(paramName, paramValue, paramsValidationErros, 5)) {
                    paramTo = paramValue;
                }
            }
            if(!(paramName.equals(HTTP_PARAM_FAMILY) || 
                 paramName.equals(HTTP_PARAM_SUBFAMILY) || 
                 paramName.equals(HTTP_PARAM_CLASE) || 
                 paramName.equals(HTTP_PARAM_FROM) || 
                 paramName.equals(HTTP_PARAM_TO)) ) {
                   
                paramsValidationErros.add('Not supported param [' + paramName + '].');
            }
        }
        
        if(!isParamFromProvided) {
            paramsValidationErros.add('Param [from] is required.');
        }

        if(!isParamToProvided) {
            paramsValidationErros.add('Param [to] is required.');
        }

        if(!paramsValidationErros.isEmpty()) {
            for(String err : paramsValidationErros) {
                errorDesc = errorDesc + err + ' '; 
            }
            result = '{"response":"ERROR", "desc": "' + errorDesc + '"}';
        }
        
        if(paramsValidationErros.isEmpty()) {
            listProductsQuantity = DAOService.fetchProductsQuantity(paramFamily, paramSubFamily, paramClase);
            if(!listProductsQuantity.isEmpty()) {
                prodClassification = listProductsQuantity.get(0);
                numProds = prodClassification.numberProducts;
                
                paramFromInt = Integer.valueOf(paramFrom);
                paramToInt = Integer.valueOf(paramTo);
                System.debug('params from[' + paramFromInt + '] to [' + paramToInt + ']');
                if(paramFromInt >= 1 && paramToInt <= numProds) {
                    try {
                        // get prods
                        soqlLimit = (paramToInt - paramFromInt) + 1;
                        soqlOffset = paramFromInt - 1;
                        listProds = DAOService.fetchProducts(paramFamily, paramSubFamily, paramClase, soqlLimit, soqlOffset);
                        //listProds = DAOService.fetchProducts('P-!DEA Kids', '7-Juguetes para Bebés', '04-Sonajas', soqlLimit, soqlOffset);
                        listProdResponse = new List<ProductServiceResponse>();
                        for(Product2 prod : listProds) {
                            prodSResp = new ProductServiceResponse(prod);
                            listProdResponse.add(prodSResp);
                        }
                        result = JSON.serialize(listProdResponse);
                    } catch (Exception ex) {
                        result = '{"response":"ERROR", "desc": "Error accessing data. Exceding resource limits"}';
                        exceptionMsg = ex.getMessage() + ' ' + '[' + soqlLimit + '] [' + soqlOffset + ']';
                    }
                } else {
                    result = '{"response":"ERROR", "desc": "Prods found [' + numProds + '] , not valid range from[' + paramFromInt + '] to[' + paramToInt + ']"}';
                }
            }
        }
        
        saveLOG(remoteAddress, result, requestUri, httpParams, exceptionMsg);

        return result;
    }
    
    private static Boolean validateSizeParamValue(String paramName, String paramValue, List<String> errors, Integer acceptedLong) {
        Integer paramValueSize;
        if(paramValue != null) {
            paramValueSize = paramValue.length();
            if(paramValueSize > acceptedLong) {
                errors.add('Param [' + paramName + '] value is too long.');
                return false;
            }
        }
        return true;
    }
    
    private static Boolean validatePositiveInteger(String paramName, String paramValue, List<String> errors, Integer acceptedLong) {
    
        if(validateSizeParamValue(paramName, paramValue, errors, acceptedLong)) {
            if(!Util.isPositiveInteger(paramValue, acceptedLong)) {
                errors.add('Param [' + paramName + '] value [' + paramValue + '] not valid. ');
                return false;
            }
        }
        return true;
    }
    
    
    private static void saveLOG(String premoteAddress, String presult, String prequestUri, Map<String, String> phttpParams, String exMsg) {
        String resultLog; 
        Poduct_Services_LOG__c productServiceLOG;

        productServiceLOG = new Poduct_Services_LOG__c();
        productServiceLOG.Fecha_Peticion__c = Datetime.now();
        productServiceLOG.Name = 'PSERVLISTPRODS';
        productServiceLOG.Remote_Address__c = premoteAddress;
        productServiceLOG.Exception_Message__c = exMsg;        
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