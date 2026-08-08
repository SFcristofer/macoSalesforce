/**
 * This class send a set of invoice data to Libra
 * It class can be executed from console
 *   
 * Use mode: This send two clients to Libra
 * List<String> ids = new List<String>();
 * ids.add('123');
 * ids.add('456');
 * LibraSimpleAltaFactura lsac = new LibraSimpleAltaFactura(ids, true);
 * lsac.execute();
 * 
 */
public class LibraSimpleAltaFactura {
    private static String TIPO_CARGA_CONTENEDOR = 'Informe Carga de Contenedor';
    private Boolean isCancelInvoice;
    private List<String> orderIds;
    public List<PedidoParentAccount> pedidosParentList;
    private Envio_Correos__c csEnvioCorreos;
    private static String ERROR_MSG_PROD_EXISTE = 'ya existe';    

    /**
     * Constructor
     * orderIds - invoice order ids to be send
     * isCancel - true if this a cancel invoice, false otherwise
     */
    public LibraSimpleAltaFactura(List<String> porderIds, Boolean isCancel) {
        isCancelInvoice = isCancel;
        orderIds = porderIds;
    }


    /**
     * Execute the Libra callout
     */
    public void execute() {
        System.debug('Execute send');
        List<String> idProds;
        List<PedidoParentAccount> ordersParentAccount;
        List<PedidoDeCompra__c> ordersToBeSent = new List<PedidoDeCompra__c>();

        ResultListSentProduct rlsp;

        ordersParentAccount = buildPedidoParentAccount();

        System.debug('ordersParentAccount.size [' + ordersParentAccount.size() + ']');

        for(PedidoParentAccount ppa : ordersParentAccount) {
            ordersToBeSent.add(ppa.pedido);
        }

        idProds = enableSendProducts(ordersToBeSent);
        rlsp = sendProducts(idProds);
        executeLibraCallout();

        //rlsp.jsonResProds = listJSONLog;
        //rlsp.prodsSent = updateResponse;
        insert rlsp.jsonResProds;
        update rlsp.prodsSent;
    }

    public List<PedidoParentAccount> buildPedidoParentAccount() {
        List<PedidoDeCompra__c> orders;
        List<Account> parentAccounts;
        List<String> parentIds = new List<String>();
        List<PedidoDeCompra__c> pedidosListos = new List<PedidoDeCompra__c>();
        List<String> fechasFacturaCompra;
        List<String> fechasFacturaVenta;
        Incremento_CS__c incAmerica;
        Incremento_CS__c incCore;
        Map<Object, Object> paramsCallout;

        orders = gerOrders();  
        
        //send products

        fechasFacturaCompra = new List<String>();
        fechasFacturaVenta = new List<String>();

        if(isCancelInvoice) {
            incAmerica = getIncrement('facturaDoAmericaCancel');
            incCore = getIncrement('facturaDoCoreCancel');
        } else {
            incAmerica = getIncrement('facturaDoAmerica');
            incCore = getIncrement('facturaDoCore');
        }
        csEnvioCorreos = DOBrandsDAO.getCSEnvioCorreos('sendInvoices');
             
        for(PedidoDeCompra__c p : orders) {
            if(!p.Documentos__r.isEmpty()) {
                pedidosListos.add(p);
                if(p.Proforma__r.Cuenta__r.ParentId != null) {
                    parentIds.add(p.Proforma__r.Cuenta__r.ParentId);
                }
            }
        }
             
        parentAccounts = [SELECT Id,
                                 Name,
                                 Codigo_rapido__c,
                                 Sociedad__c
                            FROM Account 
                           WHERE Id IN :parentIds
                             AND Codigo_rapido__c != null];
             
        pedidosParentList = crearPedidosParent(pedidosListos, parentAccounts, incAmerica, incCore, isCancelInvoice);
             
        setExchangeRates(pedidosParentList);
        return pedidosParentList;
    }


    public void executeLibraCallout() {
        LibraFacturaCompraCallout facturaCompraCallout;
        LibraFacturaVentaCallout facturaVentaCallout;
        LibraCalloutResponse lcrCompra;
        LibraCalloutResponse lcrVenta;
        Boolean addToMail = false;
        String response;
        JSON_LOG__c jsonLog;
        String jsonCancelName = isCancelInvoice ? 'Cancel' : '';

        System.debug('Sending invoices');

        List<JSON_LOG__c> listJSONLog = new List<JSON_LOG__c>();
        List<PedidoDeCompra__c> mailOrders = new List<PedidoDeCompra__c>();
        List<PedidoDeCompra__c> ordersToBeUpdated = new List<PedidoDeCompra__c>();

        for(PedidoParentAccount ppa : pedidosParentList) {
            addToMail = false;
            if(!validatePedido(ppa.pedido)) {
                continue;
            }


            if(!isCancelInvoice) {
                if(ppa.pedido.Factura_Compra_Enviada__c == false) {
                    facturaCompraCallout = new LibraFacturaCompraCallout('produccionFacturaCompra');
                    lcrCompra = facturaCompraCallout.executeCallout(ppa);
                     
                    jsonLog = new JSON_LOG__c();
                    jsonLog.name = 'libraFacturaCompra';
                    jsonLog.endpoint__c = lcrCompra.endpoint;
                    jsonLog.Fecha_Envio__c = Datetime.now();
                    jsonLog.json__c = lcrCompra.request;
                    jsonLog.Response_JSON__c = lcrCompra.response;
                    listJSONLog.add(jsonLog);
                     
                    response = processResponse(lcrCompra.response);
                    if(response.equals('OK')) {
                        ppa.pedido.Factura_Compra_Enviada__c = true;
                    } else {
                        addToMail = true;
                    }
                }
            }
            
            facturaVentaCallout = new LibraFacturaVentaCallout('produccionFacturaVenta');
            lcrVenta = facturaVentaCallout.executeCallout(ppa);
                 
            jsonLog = new JSON_LOG__c();
            jsonLog.name = 'libraFacturaVenta' + jsonCancelName;
            jsonLog.endpoint__c = lcrVenta.endpoint;
            jsonLog.Fecha_Envio__c = Datetime.now();
            jsonLog.json__c = lcrVenta.request;
            jsonLog.Response_JSON__c = lcrVenta.response;
            listJSONLog.add(jsonLog);
                 
            response = processResponse(lcrVenta.response);
            if(response.equals('OK')) {
                ppa.pedido.Factura_Venta_Enviada__c = true;
            } else {
                addToMail = true;
            }
             
            if(addToMail) {
                mailOrders.add(ppa.pedido);
            }
             
            ordersToBeUpdated.add(ppa.pedido);
        }
             
        insert listJSONLog;
        update ordersToBeUpdated;
             
        if(csEnvioCorreos != null && csEnvioCorreos.correo_electronico__c != null && !mailOrders.isEmpty()) {
            sendMail(csEnvioCorreos.correo_electronico__c, mailOrders);
        }
    }


    private void sendMail(String deliveryMail, List<PedidoDeCompra__c> mailOrders) {
        String body = '';
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] { deliveryMail };
        message.subject = 'Libra Facturas: Fallos al intentar registrar facturas';
        body = fromOrderListTpString(mailOrders);
        message.plainTextBody = 'Pedidos: \n' + body;
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        System.debug('mail sent res [' + results + ']');
    }

    private String fromOrderListTpString(List<PedidoDeCompra__c> orders) {
        String result = '\n';
        for(PedidoDeCompra__c order : orders) {
            if(!order.Factura_Compra_Enviada__c) {
                result = result + ' - Pedido [' + order.Name + '] : Fallo al registrar factura de compra [' + order.Numero_de_Factura_Proveedor__c + '] \n';
            }
            if(!order.Factura_Venta_Enviada__c) {
                result = result + ' - Pedido [' + order.Name + '] : Fallo al registrar factura de venta [' + order.Numero_de_Factura__c + '] \n';
            }
        }
        return result;
    }

    public void setExchangeRates(List<PedidoParentAccount> pedidos) {
        String dateFormat;
        Datetime datePedido;
        Date startDate;
        Date endDate;
        List<Date> lstDates = new List<Date>();
        List<Exchange_Rate__c> rates;
        Map<String, Exchange_Rate__c> mapFechaRate = new Map<String, Exchange_Rate__c>();
        Exchange_Rate__c exRate;

        for(PedidoParentAccount pedidopa : pedidos) {
            if(pedidopa.pedido.Fecha_Factura__c != null) {
                datePedido = pedidopa.pedido.Fecha_Factura__c;
                datePedido = datePedido.addDays(1);
                lstDates.add(datePedido.date());

            }

            if(pedidopa.pedido.Fecha_Factura_Proveedor__c != null) {
                datePedido = pedidopa.pedido.Fecha_Factura_Proveedor__c;
                datePedido = datePedido.addDays(1);
                lstDates.add(datePedido.date());
            }
        }

        lstDates.sort();
        if(!lstDates.isEmpty()) {
            endDate = lstDates.get(lstDates.size() - 1);
            startDate = lstDates.get(0);
            startDate = startDate.addDays(-15);
        }

        rates = DOBrandsDAO.getExchangeRates(startDate, endDate);

        for(Exchange_Rate__c er : rates) {
            mapFechaRate.put(er.Name, er);
        }

        for(PedidoParentAccount pedidopa : pedidos) {
        
            if(pedidopa.parentAccount.Sociedad__c == null || pedidopa.parentAccount.Sociedad__c.equals('')) {
                throw new DoBrandsException('Parent account has not Sociedad value');
            }

            if (pedidopa.parentAccount.Sociedad__c.equals('Do Core') || pedidopa.parentAccount.Sociedad__c.equals('Do América')) {
                if(pedidopa.pedido.Fecha_Factura__c != null) {
                    datePedido = pedidopa.pedido.Fecha_Factura__c;
                    datePedido = datePedido.addDays(1);
                    dateFormat = datePedido.format('yyyy-MM-dd');
                    exRate = getValidExchangeRate(mapFechaRate, datePedido);

                    if(exRate !=null ) {
                        pedidopa.exchangeRateCliente = String.valueOf(exRate.Rate_Euro_Currency__c.setScale(4));
                    } else {
                        pedidopa.exchangeRateCliente = '-1';
                    }
                }

                if(pedidopa.pedido.Fecha_Factura_Proveedor__c != null) {
                    datePedido = pedidopa.pedido.Fecha_Factura_Proveedor__c;
                    datePedido = datePedido.addDays(1);
                    dateFormat = datePedido.format('yyyy-MM-dd');
                    exRate = getValidExchangeRate(mapFechaRate, datePedido);

                    if(exRate !=null ) {
                        pedidopa.exchangeRateProveedor = String.valueOf(exRate.Rate_Euro_Currency__c.setScale(4));
                    } else {
                        pedidopa.exchangeRateProveedor = '-1';
                    }
                }
            }
        }
    }


    public Exchange_Rate__c getValidExchangeRate(Map<String, Exchange_Rate__c> mapDateExRate, Datetime dateToSearch) {
        Integer limitLoop = 0;
        Exchange_Rate__c exchangeRate = null;
        String dateFormat;
        while(exchangeRate == null && limitLoop < 10) {
            limitLoop++;
            dateFormat = dateToSearch.format('yyyy-MM-dd');
            exchangeRate = mapDateExRate.get(dateFormat);
            dateToSearch = dateToSearch.addDays(-1);
        }
        return exchangeRate;
    }

    //verifica que todos los pedido line items tengan codigo de articulo
    //si un producto no tiene ese dato, no se puede registrar
    private boolean validatePedido(PedidoDeCompra__c pcompra) {
        Boolean result = true;
        List<PedidoLineItem__c> pliList;
        pliList = pcompra.PedidoLineItems__r;
        for(PedidoLineItem__c pli : pliList) {
            if(pli.CodigoProducto__c == null) {
                result = false;
            }
        }
        return result;
    }

    private List<PedidoParentAccount> crearPedidosParent(List<PedidoDeCompra__c> pedidos, List<Account> parents, Incremento_CS__c america, Incremento_CS__c core, Boolean isCancel) {
        List<String> idPedidos;
        PedidoParentAccount pedidoParent;
        Account parent;
        String parentId;
        List<PedidoParentAccount> pedidosParentAccounts = new List<PedidoParentAccount>();
        idPedidos = new List<String>();
        for(PedidoDeCompra__c p : pedidos) {
            pedidoParent = new PedidoParentAccount();
            pedidoParent.pedido = p;
            pedidoParent.isCancel = isCancel;
            parentId = p.Proforma__r.Cuenta__r.ParentId;
            parent = findParent(parents, parentId);
            if(parent != null) {
                pedidoParent.parentAccount = parent;
                pedidosParentAccounts.add(pedidoParent);
                idPedidos.add(p.Id);
            }
            pedidoParent.prefixInvoiceDoAmerica = america.prefix__c;
            pedidoParent.prefixInvoiceDoCore = core.prefix__c;

            if(isCancel) {
                pedidoParent.prefixInvoiceDoAmerica = america.prefix_cancel__c;
                pedidoParent.prefixInvoiceDoCore = core.prefix_cancel__c;
            }
        }

        return pedidosParentAccounts;
    }

    private Account findParent(List<Account> parents, String pparentId) {
        Account parent;
        for(Account a : parents) {
            if(a.Id.equals(pparentId)) {
                return a;
            }
        }
        return parent;
    }
    
    
    private Incremento_CS__c getIncrement(String name) {
        Incremento_CS__c increaseCS;

        // Obtener valores
        increaseCS = [SELECT Id, 
                             Name, 
                             prefix__c, 
                             year__c, 
                             prefix_cancel__c,
                             consecutive__c 
                        FROM Incremento_CS__c
                       WHERE Name = :name];
        return increaseCS;
    }


    public String processResponse(String response) {
        LibraStatusResponse resultAltaCliente;
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
            }
        } catch(JSONException je) {
            result = response;
            System.debug('Malformed json response [' + result + ']');            
        }
        return result;
    }


    public List<PedidoDeCompra__c> gerOrders() {
        List<PedidoDeCompra__c> orders;

        orders = [SELECT Id, 
                         Name,
                         NumeroDeContenedor__c,
                         N_de_Seal__c,
                         Enviado_libra__c,
                         Numero_de_Factura__c, 
                         Numero_de_Factura_Proveedor__c,
                         Fecha_Factura__c, 
                         CostoOrigen__c, 
                         Precio_Total__c, 
                         Fecha_Factura_Proveedor__c,
                         Fecha_Cancelacion_Factura__c,
                         Proforma__r.Cuenta__r.Codigo_rapido__c,
                         Proforma__r.Cuenta__r.Sociedad__c,
                         Proforma__r.Cuenta__r.ParentId,
                         Proforma__r.CurrencyIsoCode,
                         Aprobado_Envio__c, 
                         CurrencyIsoCode,
                         Proveedor__c,
                         Factura_Compra_Enviada__c,
                         Factura_Venta_Enviada__c,
                         Proveedor__r.Codigo_rapido__c,
                         (SELECT Id, 
                                 Name 
                            FROM Documentos__r
                           WHERE Tipo_de_Documento__c = :TIPO_CARGA_CONTENEDOR),
                         (SELECT Id,
                                 CodigoProducto__c,
                                 CostoOrigen__c,
                                 CostoTotalUnitario__c,
                                 PrecioDeVenta__c,
                                 PrecioDeVentaTot__c,
                                 Unidades__c,
                                 UnidadesPorMasterbox__c,
                                 NumeroDeCajas__c,
                                 CostoOrigenTot__c,
                                 Producto__c,
                                 Producto__r.Codigo_Anterior2__c,
                                 Producto__r.CodigoDeProductoBase__c
                            FROM PedidoLineItems__r)
                    FROM PedidoDeCompra__c
                   WHERE Id IN :orderIds
                     AND RecordType.DeveloperName != 'Simulacion' 
                     AND RecordType.DeveloperName != 'Simulacion_Aprobador' 
                     AND NumeroDeContenedor__c != null
                     AND N_de_Seal__c != null
                     AND Fecha_Factura_Proveedor__c != null
                     AND Fecha_Factura__c != null
                     AND ((Factura_Compra_Enviada__c = false AND Factura_Venta_Enviada__c = false) OR (Factura_Venta_Enviada__c = true AND Factura_Venta_Enviada__c = :isCancelInvoice))
                     AND Aprobado_Envio__c = true];
        return orders;        
    }


    public List<String> enableSendProducts(List<PedidoDeCompra__c> ordersToBeSent) {
        System.debug('enableSendProducts');
        Set<String> codesProduct = new Set<String>();
        Map<String, List<String>> codeProductIdsOrder = new Map<String, List<String>>();
        List<PedidoLineItem__c> pliList;
        List<Product2> enabledSentProducts = new List<Product2>();

        System.debug('ordersToBeSent.size[' + ordersToBeSent.size() + ']');
        for(PedidoDeCompra__c o : ordersToBeSent) {
            pliList = o.PedidoLineItems__r;
            for(PedidoLineItem__c pli : pliList) {
                if(pli.CodigoProducto__c != null) {
                    codesProduct.add(pli.CodigoProducto__c);
                }
            }
        }

        List<String> idProds = new List<String>();
        List<Product2> productsToBeRegistered = [SELECT Id, 
                                                        Name, 
                                                        CodigoDeProductoBase__c, 
                                                        RecordType.DeveloperName, 
                                                        Registrado_Libra__c 
                                                   FROM Product2 
                                                  WHERE CodigoDeProductoBase__c IN :codesProduct
                                                    AND RecordType.DeveloperName = 'Producto'];

        for(Product2 product : productsToBeRegistered) {
            product.Registrado_Libra__c = false;
            idProds.add(product.Id);
            //enabledSentProducts.add(product);
        }

        //update enabledSentProducts;

        System.debug('idProds.size[' + idProds.size() + ']');

        //LibraSimpleAltaProducto lsap = new LibraSimpleAltaProducto(idProds, '200');
        //lsap.execute();

        return idProds;
    }


    public ResultListSentProduct sendProducts(List<String> idProds) {
        List<Product2> productos;
        List<Sociedades__mdt> sociedades;
        Set<String> idsFactory;
        List<Product2> baseProducts;
        Map<String, Proforma__c> factoryProforma;
        String sociedadesStr = '';
        List<Product2> updateResponse = new List<Product2>();
        String response;

        productos = getProducts(idProds);

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

        ResultListSentProduct rlsp = new ResultListSentProduct();

        for(Sociedades__mdt soc : sociedades) {
            sociedadIdentifier = String.valueOf(soc.Identificador_Sociedad__c);
            System.debug('sociedadIdentifier[' + sociedadIdentifier + ']');            
            if(sociedadIdentifier.equals('200')) {

                for(Product2 p : productos) {
                    pbl = new ProductBatchLibra(p, String.valueOf(soc.Identificador_Sociedad__c), factoryProforma);

                    System.debug('prod[' + pbl.product.CodigoDeProductoBase__c + ']');                    
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
                  
                        response = processResponseProduct(lcr.response);
                  
                        if(response.equals('OK')) {
                            p.Registrado_Libra__c = true;
                            if(!existProductToUpdate(updateResponse, p)) {
                                updateResponse.add(p);
                            }
                        } else {
                            System.debug('Res error[' + response + ']');
                        }                        
                    } else {
                        System.debug('product validation[' + pbl.validationResult + ']');                        
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

        rlsp.jsonResProds = listJSONLog;
        rlsp.prodsSent = updateResponse;

        return rlsp;
        //insert listJSONLog;

        //update updateResponse;
    }


    public List<Product2> getProducts(List<String> productIds) {
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
                   ORDER BY CodigoDeProductoBase__c];

        return productos;
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

    public String processResponseProduct(String response) {
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


    class ResultListSentProduct {
        public List<JSON_LOG__c> jsonResProds;
        public List<Product2> prodsSent;
    }

}