public class QBInvoiceQueryController {
    private static String ESTADO_QUERY_QB = 'Contabilizada';
    private static String ESTADO_COBRADA_SF = 'Cobrada';
    private static String ESTADO_CANCEL_SF = 'Cancelada';
    private static String INVOICE_VOID_QB = 'Voided';

    private List<FacturaDeCliente__c> facturasCliente;
    private QBCallout qbCallout;
    private String jsonLogName;
    public Boolean successfulInvoicesUpdate {set; get;}


    public QBInvoiceQueryController() {
        facturasCliente = QBDAO.getFacturaClienteByEstado(ESTADO_QUERY_QB);
        initController();
    }
    
    public QBInvoiceQueryController(List<FacturaDeCliente__c> facturas) {
        facturasCliente = facturas;
        initController();
    }


    private void initController() {
        jsonLogName = 'QBQueryInvoice';
        successfulInvoicesUpdate = false;
        qbCallout = new QBInvoiceQueryCallout('QBConfig');
    }
    
    public String sendToQB() {
        Boolean isErrorResponse = false;
        QBCalloutResponse calloutResponse;
        QBInvoiceQueryResponse invoiceQueryResponse;
        QBInvoiceQueryResponseList qrList;
        List<QBInvoiceQueryResponseInvoice> invoicesResponse;
        List<FacturaDeCliente__c> facturasToUpdate;
        Map<String, QBInvoiceQueryResponseInvoice> mapInvoicesResponse;
        QBInvoiceQueryResponseInvoice invoiceQB;
        
        JSON_LOG__c jsonLog;
        
        System.debug('Query invoices ...');
        System.debug('no. facturas cliente[' + facturasCliente.size() + ']');
        
        mapInvoicesResponse = new Map<String, QBInvoiceQueryResponseInvoice>();
        facturasToUpdate = new List<FacturaDeCliente__c>();
        
        calloutResponse = qbCallout.executeCallout(facturasCliente);
        System.debug('QBQI CTRLR: ' + calloutResponse.response);
               
        if(calloutResponse.response.contains('error') || calloutResponse.response.contains('Error')) {
            System.debug('ERROR QB');
            isErrorResponse = true;
        }
               
        jsonLog = new JSON_LOG__c();
           
        jsonLog.name = jsonLogName;
        jsonLog.endpoint__c = calloutResponse.endpoint;
        jsonLog.Fecha_Envio__c = Datetime.now();
        jsonLog.json__c = calloutResponse.request;
        jsonLog.Response_JSON__c = calloutResponse.response;
        insert jsonLog;
           
        if(!isErrorResponse) {
            invoiceQueryResponse = (QBInvoiceQueryResponse)calloutResponse.responseObject;
            
            if(invoiceQueryResponse != null) {
                qrList = invoiceQueryResponse.QueryResponse;
                if(qrList != null) {
                    invoicesResponse = qrList.Invoice;
                    if(invoicesResponse != null) {
                        for(QBInvoiceQueryResponseInvoice iqr : invoicesResponse) {
                            mapInvoicesResponse.put(iqr.Id, iqr);
                        }
                    }
                }
            }
            
            for(FacturaDeCliente__c fcliente : facturasCliente) {
                invoiceQB = mapInvoicesResponse.get(fcliente.IdQbo__c);
                if(invoiceQB != null) {
                    System.debug('fclienteIdQbo[' + fcliente.IdQbo__c + '] invoiceId[' + invoiceQB.Id + '] Balance[' + invoiceQB.Balance + '] PrivateNote[' + invoiceQB.PrivateNote + ']');
                    if(invoiceQB.Balance.equals('0') && invoiceQB.PrivateNote == null) {
                        System.debug('fclienteIdQbo[' + fcliente.IdQbo__c + '] COBRADA');
                        fcliente.Estado__c = ESTADO_COBRADA_SF;
                        facturasToUpdate.add(fcliente);
                    }
                    if(invoiceQB.Balance.equals('0') && invoiceQB.PrivateNote != null && invoiceQB.PrivateNote.equals(INVOICE_VOID_QB)) {
                        System.debug('fclienteIdQbo[' + fcliente.IdQbo__c + '] CANCELADA');
                        fcliente.Estado__c = ESTADO_CANCEL_SF;
                        facturasToUpdate.add(fcliente);
                    }
                }
            }
            update facturasToUpdate;
            
            successfulInvoicesUpdate = true;
        }

        return null;
    }

}