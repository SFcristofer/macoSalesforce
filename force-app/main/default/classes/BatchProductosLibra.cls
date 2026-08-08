global class BatchProductosLibra implements Database.Batchable<sObject>, Database.AllowsCallouts {

    private static String ERROR_MSG_PROD_EXISTE = 'El articulo ya existe en la base de datos';

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //get products
        return Database.getQueryLocator([SELECT Id, 
                                                Name, 
                                                ProductCode,
                                                CodigoDeProductoBase__c, 
                                                Descripcion__c, 
                                                Descripcion_Larga__c,
                                                PlazoDeFabricacion__c,
                                                Registrado_Libra__c,
                                                (SELECT Id,
                                                        Name,
                                                        Fabrica__c,
                                                        Fabrica__r.Name,
                                                        Fabrica__r.Codigo_rapido__c,
                                                        Fabrica__r.Description,
                                                        PlazoDeFabricacion__c
                                                   FROM FabricasDelProducto__r) //ProductoBase__c
                                           FROM Product2 
                                          WHERE CodigoDeProductoBase__c != null 
                                            AND RecordType.DeveloperName = 'Producto'
                                            AND Registrado_Libra__c = false
                                       ORDER BY CodigoDeProductoBase__c]);

    }

    global void execute(Database.BatchableContext BC, List<Product2> productos) {
        Set<String> idsFactory;
        Map<String, Proforma__c> factoryProforma;
        List<Product2> baseProducts;
        String response;
        List<Product2> updateResponse = new List<Product2>();
        String sociedadesStr = '';
        String sociedadesStrDiff = '';
        String[] tokens;

        List<Sociedades__mdt> sociedades = DOBrandsDAO.getSociedades('USD');

        //get base factory
        idsFactory = new Set<String>();
        for(Product2 p : productos) {
            baseProducts = p.FabricasDelProducto__r;
            for(Product2 pBase : baseProducts) {
                idsFactory.add(pbase.Fabrica__c);
            }
        }

        //get factory with proforma
        factoryProforma = getFactoriesWithProforma(idsFactory);

        for(Sociedades__mdt soc : sociedades) {
            sociedadesStr = sociedadesStr + soc.Identificador_Sociedad__c + ';';
        }
        sociedadesStr = sociedadesStr.substring(0, sociedadesStr.length() - 1);

        System.debug('sociedadesStr [' + sociedadesStr + ']');

        ProductBatchLibra pbl;
        LibraProductosCallout callout;
        JSON_LOG__c jsonLog;

        List<JSON_LOG__c> listJSONLog = new List<JSON_LOG__c>();
        LibraCalloutResponse lcr;

        for(Sociedades__mdt soc : sociedades) {
            for(Product2 p : productos) {
                pbl = new ProductBatchLibra(p, String.valueOf(soc.Identificador_Sociedad__c), factoryProforma);
           
                if(pbl.validateProduct()) {
                    callout = new LibraProductosCallout('produccionProductos');
                    lcr = callout.executeCallout(pbl);
    
                    jsonLog = new JSON_LOG__c();
                    jsonLog.name = 'libraProductos';
                    jsonLog.endpoint__c = lcr.endpoint;
                    jsonLog.Fecha_Envio__c = Datetime.now();
                    jsonLog.json__c = lcr.request;
                    jsonLog.Response_JSON__c = lcr.response;
                    listJSONLog.add(jsonLog);
    
                    response = processResponse(lcr.response);
    
                    if(response.equals('OK')) {
                        p.Registrado_Libra__c = true;
                        if(!existProductToUpdate(updateResponse, p)) {
                            updateResponse.add(p);
                        }
    
                    } else {
                        System.debug('Res error[' + response + ']');
                    }
                } else {
                    if(!pbl.validationResult.startsWith(ProductBatchLibra.ERROR_VALIDATION_PRODUCTS) && 
                       !pbl.validationResult.contains(ProductBatchLibra.ERROR_VALIDATION_NO_PROFORMA)) {
                        jsonLog = new JSON_LOG__c();
                        jsonLog.name = 'libraProductos';
                        jsonLog.endpoint__c = 'NO ENDPOINT';
                        jsonLog.Fecha_Envio__c = Datetime.now();
                        jsonLog.json__c = 'Internal Error Product';
                        jsonLog.Response_JSON__c = pbl.validationResult;
                        listJSONLog.add(jsonLog);
                    }
                }
            }
        }
        insert listJSONLog;

        update updateResponse;
    }

    global void finish(Database.BatchableContext BC) {
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
               if(response.contains(ERROR_MSG_PROD_EXISTE)) { //El articulo ya existe en la base de datos
                   result = 'OK';
               }
            }
        } catch (JSONException je) {
            result = response;
        }
        return result;
    }
    
    
    public boolean existProductToUpdate(List<product2> products, Product2 productToFind) {
        for(Product2 prod : products) {
            if(prod.Id == productToFind.Id) {
                return true;
            }
        }
        return false;
    }


    private Map<String, Proforma__c> getFactoriesWithProforma(Set<String> factories) {
        Map<String, Proforma__c> factoryProforma = new Map<String, Proforma__c>();
        List<Proforma__c> proformas;

        proformas = [SELECT Id, 
                            Name, 
                            EstudioOportunidad__c,
                            EstudioOportunidad__r.Fabrica__c,
                            EstudioOportunidad__r.Fabrica__r.Name,
                            RecordType.DeveloperName	   
                       FROM Proforma__c 
                      WHERE EstudioOportunidad__r.Fabrica__c IN :factories];

        for(Proforma__c pr : proformas) {
            factoryProforma.put(pr.EstudioOportunidad__r.Fabrica__c, pr);
        }
        return factoryProforma;
    }

}