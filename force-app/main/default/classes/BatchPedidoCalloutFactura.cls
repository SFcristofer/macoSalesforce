global class BatchPedidoCalloutFactura implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    private static String TIPO_CARGA_CONTENEDOR = 'Informe Carga de Contenedor';
    private static String REGEX_INVOICE_EXIST = '.+La factura .+ ya existe\\"\\}\\}';

    global BatchPedidoCalloutFactura() {
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, 
                                                Name,
                                                NumeroDeContenedor__c,
                                                N_de_Seal__c,
                                                Enviado_libra__c,
                                                Numero_de_Factura__c, //numero_secuencia
                                                Numero_de_Factura_Proveedor__c,
                                                Fecha_Factura__c, //fecha_factura
                                                Fecha_Factura_Proveedor__c,
                                                Proforma__r.Cuenta__r.Codigo_rapido__c,
                                                Proforma__r.Cuenta__r.Parent.Sociedad__c,
                                                Proforma__r.Cuenta__r.ParentId,
                                                Proforma__r.CurrencyIsoCode,
                                                Aprobado_Envio__c, 
                                                CurrencyIsoCode,
                                                Proveedor__c,
                                                CostoOrigen__c, 
                                                Precio_Total__c, 
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
                                          WHERE RecordType.DeveloperName != 'Simulacion' 
                                            AND RecordType.DeveloperName != 'Simulacion_Aprobador' 
                                            AND NumeroDeContenedor__c != null
                                            AND N_de_Seal__c != null
                                            AND Fecha_Factura_Proveedor__c != null
                                            AND Fecha_Factura__c != null
                                            AND (Factura_Compra_Enviada__c = false OR Factura_Venta_Enviada__c = false) 
                                            AND Aprobado_Envio__c = true]);
    }

    global void execute(Database.BatchableContext BC, List<PedidoDeCompra__c> scope) {
        List<PedidoParentAccount> pedidosParentList;
        List<Account> parentAccounts;
        List<String> parentIds = new List<String>();
        List<PedidoDeCompra__c> pedidosListos = new List<PedidoDeCompra__c>();
        List<PedidoDeCompra__c> ordersToBeUpdated = new List<PedidoDeCompra__c>();        
        LibraFacturaCompraCallout facturaCompraCallout;
        LibraFacturaVentaCallout facturaVentaCallout;
        List<String> fechasFacturaCompra;
        List<String> fechasFacturaVenta;
        Incremento_CS__c incAmerica;
        Incremento_CS__c incCore;
        Envio_Correos__c csEnvioCorreos;
        List<PedidoDeCompra__c> mailOrders = new List<PedidoDeCompra__c>();
        Boolean addToMail = false;
        
        JSON_LOG__c jsonLog;
        List<JSON_LOG__c> listJSONLog = new List<JSON_LOG__c>();
        LibraCalloutResponse lcrCompra;
        LibraCalloutResponse lcrVenta;

        String response;

        Map<Object, Object> paramsCallout;

        List<String> idsPedidos = new List<String>();

        fechasFacturaCompra = new List<String>();
        fechasFacturaVenta = new List<String>();
        
        incAmerica = getIncrement('facturaDoAmerica');
        incCore = getIncrement('facturaDoCore');

        csEnvioCorreos = DOBrandsDAO.getCSEnvioCorreos('sendInvoices');

        for(PedidoDeCompra__c p : scope) {
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

        pedidosParentList = crearPedidosParent(pedidosListos, parentAccounts, incAmerica, incCore);

        setExchangeRates(pedidosParentList);

        for(PedidoParentAccount ppa : pedidosParentList) {
            addToMail = false;
            if(!validatePedido(ppa.pedido)) {
                continue;
            }
            
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
                    ppa.pedido.Enviado_libra__c = true;
                } else {
                    addToMail = true;
                }
            }

            if(ppa.pedido.Factura_Venta_Enviada__c == false) {
                facturaVentaCallout = new LibraFacturaVentaCallout('produccionFacturaVenta');
                lcrVenta = facturaVentaCallout.executeCallout(ppa);
    
                jsonLog = new JSON_LOG__c();
                jsonLog.name = 'libraFacturaVenta';
                jsonLog.endpoint__c = lcrVenta.endpoint;
                jsonLog.Fecha_Envio__c = Datetime.now();
                jsonLog.json__c = lcrVenta.request;
                jsonLog.Response_JSON__c = lcrVenta.response;
                listJSONLog.add(jsonLog);
    
                response = processResponse(lcrVenta.response);
                if(response.equals('OK')) {
                    ppa.pedido.Factura_Venta_Enviada__c = true;
                    ppa.pedido.Enviado_libra__c = true;
                } else {
                    addToMail = true;
                }
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


    global void finish(Database.BatchableContext BC) {
        
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

    private List<PedidoParentAccount> crearPedidosParent(List<PedidoDeCompra__c> pedidos, List<Account> parents, Incremento_CS__c america, Incremento_CS__c core) {
        List<String> idPedidos;
        PedidoParentAccount pedidoParent;
        Account parent;
        String parentId;
        List<PedidoParentAccount> pedidosParentAccounts = new List<PedidoParentAccount>();
        idPedidos = new List<String>();
        for(PedidoDeCompra__c p : pedidos) {
            pedidoParent = new PedidoParentAccount();
            pedidoParent.pedido = p;
            parentId = p.Proforma__r.Cuenta__r.ParentId;
            parent = findParent(parents, parentId);
            if(parent != null) {
                pedidoParent.parentAccount = parent;
                pedidosParentAccounts.add(pedidoParent);
                idPedidos.add(p.Id);
            }
            pedidoParent.prefixInvoiceDoAmerica = america.prefix__c;
            pedidoParent.prefixInvoiceDoCore = core.prefix__c;
            
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
                             consecutive__c 
                        FROM Incremento_CS__c
                       WHERE Name = :name];
        return increaseCS;
    }


    public String processResponse(String response) {
        LibraStatusResponse resultAltaCliente;
        System.debug('CALL X RESULT[' + response + ']');
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
               if(Pattern.matches(REGEX_INVOICE_EXIST, response)) { 
                   result = 'OK';
               }
            }
        } catch (JSONException je) {
            result = response;
            System.debug('Malformed json response [' + result + ']');
        }
        return result;
    }

}