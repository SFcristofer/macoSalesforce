public class FacturasLibraAprobacion {
    List<PedidoDeCompra__c> pedidosList;
    public List<PedidoParentAccount> pedidosParentList {set; get;}
    public String selectedAprobacion {get;set;}
    public List<PedidoParentAccount> invalidDateInvoiceOrders {set; get;}   
    public List<PedidoParentAccount> pedidosSeleccionados {set; get;}
    List<PedidoDeCompra__c> pedidosAprobados;
    private List<String> emailNotificationList;
    private String currentBaseURL;

    private static String TIPO_CARGA_CONTENEDOR = 'Informe Carga de Contenedor';
    private static String INVALID_INVOICE_DATE = 'La factura del proveedor no tiene una fecha valida';
    private static String EMAIL_SUBJECT = 'Aprobación Facturas para envío'; 

    public FacturasLibraAprobacion() {
        initPedidos();
    }

    public void initPedidos() {
        /*List<Envio_Correos__c> csEnvioCorreosList;
        emailNotificationList = new List<String>();
        currentBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
        System.debug('currentBaseURL [' + currentBaseURL + ']');
        pedidosList = getPedidos();
        pedidosParentList = procesarPedidos(pedidosList);
        selectedAprobacion = 'Facturas';
        invalidDateInvoiceOrders = new List<PedidoParentAccount>();
        csEnvioCorreosList = Util.getCSCorreosTransferencia('aprobacionFacturas');
        for(Envio_Correos__c cs : csEnvioCorreosList) {
            emailNotificationList.add(cs.correo_electronico__c);
        }*/
    }

    private List<PedidoParentAccount> procesarPedidos(List<PedidoDeCompra__c> scope) {
        List<PedidoParentAccount> pedidosParentList;
        List<Account> parentAccounts;
        List<String> parentIds = new List<String>();
        List<PedidoDeCompra__c> pedidosListos = new List<PedidoDeCompra__c>();

        Map<Object, Object> paramsCallout;

        List<String> idsPedidos = new List<String>();

        for(PedidoDeCompra__c p : scope) {
            if(p.Documentos__r != null) {
                pedidosListos.add(p);
                parentIds.add(p.Proforma__r.Cuenta__r.ParentId);
            }
        } 

        parentAccounts = [SELECT Id,
                                 Name,
                                 Codigo_rapido__c,
                                 Sociedad__c
                            FROM Account 
                           WHERE Id IN :parentIds];

        pedidosParentList = crearPedidosParent(pedidosListos, parentAccounts);
        return pedidosParentList;
    }


    public List<PedidoDeCompra__c> getPedidos() {
        List<PedidoDeCompra__c> pedidos;
        pedidos = [SELECT Id, 
                          Name,
                          NumeroDeContenedor__c,
                          N_de_Seal__c,
                          ETD__c,
                          Precio_Total__c,
                          Enviado_libra__c,
                          Numero_de_Factura__c, //numero_secuencia
                          Numero_de_Factura_Proveedor__c,
                          Fecha_Factura_Proveedor__c,
                          Fecha_Factura__c, //fecha_factura
                          Proforma__r.Cuenta__r.Codigo_rapido__c,
                          Proforma__r.Cuenta__r.Parent.Sociedad__c,
                          Proforma__r.Cuenta__r.ParentId,
                          Proveedor__r.Name,
                          CostoTotal__c,
                          CostoOrigen__c,
                          CurrencyIsoCode,
                          (SELECT Id, 
                                  Name 
                             FROM Documentos__r 
                            WHERE Tipo_de_Documento__c = :TIPO_CARGA_CONTENEDOR),
                          (SELECT Id,
                                  CodigoProducto__c,
                                  CostoOrigen__c,
                                  PrecioDeVenta__c,
                                  Unidades__c,
                                  NumeroDeCajas__c,
                                  CostoOrigenTot__c,
                                  Producto__c,
                                  Producto__r.Codigo_Anterior2__c
                             FROM PedidoLineItems__r)
                     FROM PedidoDeCompra__c
                    WHERE NumeroDeContenedor__c != null
                      AND N_de_Seal__c != null
                      AND Enviado_libra__c = false 
                      AND Aprobado_Envio__c = false
                 ORDER BY Name];
        return pedidos;
    }


    private List<PedidoParentAccount> crearPedidosParent(List<PedidoDeCompra__c> pedidos, List<Account> parents) {
        List<PedidoLineItem__history> pliHistoryList;
        List<String> idPedidos;
        PedidoParentAccount pedidoParent;
        Account parent;
        String parentId;
        Integer counter = 1;
        List<PedidoParentAccount> pedidosParentAccounts = new List<PedidoParentAccount>();
        idPedidos = new List<String>();
        for(PedidoDeCompra__c p : pedidos) {
            pedidoParent = new PedidoParentAccount();
            pedidoParent.urlOrder = currentBaseURL + '/' + p.Id;
            pedidoParent.pedido = p;
            parentId = p.Proforma__r.Cuenta__r.ParentId;
            parent = findParent(parents, parentId);
            pedidoParent.parentAccount = parent;
            pedidoParent.consecutivo = counter;
            pedidosParentAccounts.add(pedidoParent);
            idPedidos.add(p.Id);
            if(!isValidDate(p.Fecha_Factura_Proveedor__c, p.Fecha_Factura__c == null ? Date.today() : p.Fecha_Factura__c )) {
                pedidoParent.hasValidDate = false;
                pedidoParent.alertMsg = INVALID_INVOICE_DATE;
            }
            counter ++;
        }

        pliHistoryList = getHistoryData(idPedidos);

        for(PedidoParentAccount ppa : pedidosParentAccounts) {
           ppa.pliHistoryList = pliHistoryList;
           ppa.getAlertMessages();
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

    private List<PedidoLineItem__history> getHistoryData(List<String> idPedidos) {
        List<PedidoLineItem__history> historyRecords;
        historyRecords = [SELECT OldValue,
                                 NewValue, 
                                 Field, 
                                 Parent.Id, 
                                 Parent.Name,
                                 Parent.PedidoDeCompra__c
                            FROM PedidoLineItem__History
                           WHERE Parent.PedidoDeCompra__c IN :idPedidos
                           AND Field IN ('CostoOrigen__c','NumeroDeCajas__c')]; //??? si se repiten ??

        return historyRecords;
    }


    public PageReference aprobar() {
       PageReference pr;

       //update pedidosAprobados;
       //buildAndSendMessage(emailNotificationList, EMAIL_SUBJECT);
       //initPedidos();

       pr = new PageReference('/apex/FacturasLibraAprobacion');
       pr.setRedirect(true);
       return pr;
    }


    private Boolean isValidDate(Date purchaseInvoiceDate, Date salesInvoiceDate) {
        if(purchaseInvoiceDate != null && salesInvoiceDate != null &&
           purchaseInvoiceDate.year() == salesInvoiceDate.year() && 
           purchaseInvoiceDate.month() == salesInvoiceDate.month()) {
            return true;
        }
        return false;
    }

    public PageReference selectInvoices() {
        PageReference pr;

        Integer mesFactura;
        Integer mesAprobacion;
        String accSociedad;
        List<PedidoDeCompra__c> pedidosFechasInconsistentes = new List<PedidoDeCompra__c>();
        pedidosAprobados = new List<PedidoDeCompra__c>();
        pedidosSeleccionados = new List<PedidoParentAccount>();
        for(PedidoParentAccount ppa : pedidosParentList) {
            if(ppa.selected != null && ppa.selected) {
                ppa.pedido.Aprobado_Envio__c = true;
                if(ppa.pedido.Fecha_Factura__c == null) {
                    ppa.pedido.Fecha_Factura__c = Date.today();
                } 
                pedidosAprobados.add(ppa.pedido);
                pedidosSeleccionados.add(ppa);
            }
        }
 
        pr = new PageReference('/apex/FacturasLibraAprobacionResumen');
        return pr;
    }

    public PageReference changePage() {
        PageReference pr;
        pr = new PageReference('/apex/SolicitudTransferenciaAprobacion');
        pr.setRedirect(true);
        return pr;
    }


    public PageReference regresar() {
        PageReference pr;
        pr = new PageReference('/apex/FacturasLibraAprobacion');
        return pr;
    }


    private static void buildAndSendMessage(List<String> deliveryMail, String subject) {
        String pageAsString;
        /*PageReference pr = Page.FacturasLibraAprobacionEmailTemplate;
        
        if(Test.isRunningTest()) {
            pageAsString = 'tst';
        } else {
            pageAsString = pr.getContent().tostring();
        }

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = deliveryMail;
        message.subject = subject;
        message.htmlBody = pageAsString;        
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
  
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);*/
     }
  
}