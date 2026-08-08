/**
 * This class send a set of products to Libra
 * It class should be executed from console, since it is not called from 
 * support classes.
 * 
 * Use mode: This send two products only for 200 partenrship code
 * List<String> ids = new List<String>();
 * ids.add('123');
 * ids.add('456');
 * LibraSimpleAltaProducto lsap = new LibraSimpleAltaProducto(ids, '200');
 * lsap.execute();
 * 
 * Use mode: This get a debugger list of not valid products.
 * Not valid products:
 *   - Base product that does not have associated factories
 *   - Factory product that does not have Libra code
 * LibraSimpleAltaProducto lsap = new LibraSimpleAltaProducto();
 * lsap.listProductsNotValid();
 */
public class LibraSimpleAltaProducto {
    private static String ERROR_MSG_PROD_EXISTE = 'ya existe';
    private List<String> productIds;
    //200,400,...
    private String validSociedad;

    public LibraSimpleAltaProducto(List<String> pproductIds, String pvalidSociedad) {
        productIds = pproductIds;
        validSociedad = pvalidSociedad;
    }

    public LibraSimpleAltaProducto() {
    }

    public void execute() {
        Set<String> idsFactory;
        Map<String, Proforma__c> factoryProforma;
        List<Product2> baseProducts;
        String response;
        List<Product2> updateResponse = new List<Product2>();
        String sociedadesStr = '';
        String sociedadesStrDiff = '';
        String[] tokens;
        List<Sociedades__mdt> sociedades;

        List<Product2> productos;

        productos = [SELECT Id, 
                            Name, 
                            ProductCode,
                            CodigoDeProductoBase__c, 
                            Fabrica__c, 
                            Descripcion__c, 
                            Descripcion_Larga__c,
                            Fabrica__r.Description,
                            PlazoDeFabricacion__c,
                            Registrado_Libra__c,
                            Fabrica__r.Codigo_rapido__c,
                            (SELECT Id,
                                    Name,
                                    Fabrica__r.Name,
                                    Fabrica__r.Codigo_rapido__c,
                                    Fabrica__r.Description,
                                    PlazoDeFabricacion__c
                               FROM FabricasDelProducto__r) 
                       FROM Product2 
                      WHERE CodigoDeProductoBase__c != null
                        AND Id IN :productIds
                        AND RecordType.DeveloperName = 'Producto'
                        AND Registrado_Libra__c = false
                   ORDER BY CodigoDeProductoBase__c];

        System.debug('SIZE [' + productos.size() + ']');
        sociedades = DOBrandsDAO.getSociedades('USD');

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
        String sociedadIdentifier;
          
        for(Sociedades__mdt soc : sociedades) {
            sociedadIdentifier = String.valueOf(soc.Identificador_Sociedad__c);
            if(sociedadIdentifier.equals(validSociedad)) {

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
                            jsonLog.endpoint__c = 'NO ENDPOINT I';
                            jsonLog.Fecha_Envio__c = Datetime.now();
                            jsonLog.json__c = 'Internal Error Product';
                            jsonLog.Response_JSON__c = pbl.validationResult;
                            listJSONLog.add(jsonLog);
                        } 
                    }                      
                }
            }
        }
        insert listJSONLog;

        update updateResponse;
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
        } catch(JSONException je) {
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


    public void listProductsNotValid() {
        List<Product2> productos;
        List<Product2> factoryProducts;        

        productos = [SELECT Id, 
                            Name, 
                            ProductCode,
                            CodigoDeProductoBase__c, 
                            Fabrica__c, 
                            Descripcion__c, 
                            Descripcion_Larga__c,
                            Fabrica__r.Description,
                            PlazoDeFabricacion__c,
                            Registrado_Libra__c,
                            Fabrica__r.Codigo_rapido__c,
                            (SELECT Id,
                                    Name,
                                    Fabrica__r.Name,
                                    Fabrica__r.Codigo_rapido__c,
                                    Fabrica__r.Description,
                                    PlazoDeFabricacion__c
                               FROM FabricasDelProducto__r) 
                       FROM Product2 
                      WHERE CodigoDeProductoBase__c != null 
                        AND RecordType.DeveloperName = 'Producto'
                   ORDER BY CodigoDeProductoBase__c];

        for(Product2 p : productos) {
            factoryProducts = p.FabricasDelProducto__r;
            if(factoryProducts != null && factoryProducts.isEmpty()) {
                System.debug('No existen productos de fábrica,' + p.Id + ',\"'+ p.Name + '\",');
            }

            for(Product2 prodBL : factoryProducts) {
                if(prodBL.Fabrica__r == null) {
                    System.debug('No tiene fábrica asociada,' + prodBL.Id + ',\"'+ prodBL.Name + '\",');
                } else if (prodBL.Fabrica__r.Codigo_rapido__c == null) {
                    System.debug('No tiene código rápido,' + prodBL.Id + ',\"'+ prodBL.Name + '\",\"' + prodBL.Fabrica__r.Name + '\"');
                }
             }
        }

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