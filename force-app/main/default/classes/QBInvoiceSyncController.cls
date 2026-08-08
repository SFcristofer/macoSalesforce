/**
 * Refactoring: May be, it should be an abstract class and each inherited class 
 * should proccess json log and factura
 */
public class QBInvoiceSyncController {
    //Se envia una factura y se registra log y se actualiza factura
    public final static String SINGLE_MODE = 'Single';
    
    //Se envia una factura a QB. Se crea un objeto log y se actualiza el objeto factura
    //pero los objetos se regresan para su posterior procesamiento
    public final static String SF_BATCH_MODE = 'Batch';
    
    private static String ESTADO_ENVIO_QB = 'Enviada';
    private static String ESTADO_ENVIO_QB_EXITOSO = 'Contabilizada';
    private FacturaDeCliente__c facturaCliente;
    private QBCallout qbCallout;
    private String jsonLogName;
    //Modo de operacion, single o batch
    private String operationMode;
    public Boolean envioExitoso {set; get;}


    public QBInvoiceSyncController(FacturaDeCliente__c factura, String mode) {
        facturaCliente = factura;
        operationMode = mode;
        initController();
    }
    
    public QBInvoiceSyncController(String idFactura, String mode) {
        facturaCliente = QBDAO.getFacturaCliente(idFactura, ESTADO_ENVIO_QB);
        operationMode = mode;
        initController();
    }
    
    private void initController() {
        jsonLogName = 'QBAddInvoice';
        envioExitoso = false;
        qbCallout = new QBInvoiceInsertCallout('QBConfig');
    }
    
    public QBInvoiceSyncResult sendToQB() {
        Boolean isErrorResponse = false;
        QBCalloutResponse calloutResponse;
        QBInvoiceCreateResponse createInvoiceResponse;
        QBInvoiceSyncResult invoiceResult;
        JSON_LOG__c jsonLog;
        String idQBooks;
        
        System.debug('sending qb invoice ...');
        System.debug('[' + facturaCliente.Id + '] [' + facturaCliente.Name + '] [' + facturaCliente.Estado__c + ']');
        
        invoiceResult = new QBInvoiceSyncResult();

        calloutResponse = qbCallout.executeCallout(facturaCliente);
        System.debug('QBCR CTRLR: ' + calloutResponse.response);
               
        if(calloutResponse.response.contains('error') || calloutResponse.response.contains('Error')) {
            System.debug('ERROR QB');
            isErrorResponse = true;
        }

        jsonLog = createJsonLog(calloutResponse);
        if(operationMode.equals(SINGLE_MODE)) {
            insert jsonLog;
        }
        if(operationMode.equals(SF_BATCH_MODE)) {
            invoiceResult.jsonLog = jsonLog;
        }

        if(!isErrorResponse) {
            createInvoiceResponse = (QBInvoiceCreateResponse)calloutResponse.responseObject;
            idQBooks = createInvoiceResponse.Invoice.Id;           

            facturaCliente.IdQbo__c = idQBooks;
            facturaCliente.Estado__c = ESTADO_ENVIO_QB_EXITOSO;
            if(operationMode.equals(SINGLE_MODE)) {
                update facturaCliente;
            }
            if(operationMode.equals(SF_BATCH_MODE)) {
                invoiceResult.factura = facturaCliente;
            }

            envioExitoso = true;
        } 

        return invoiceResult;
    }
    
    
    private JSON_LOG__c createJsonLog(QBCalloutResponse calloutResponse) {
        JSON_LOG__c jsonLog;
        
        jsonLog = new JSON_LOG__c();
   
        jsonLog.name = jsonLogName;
        jsonLog.endpoint__c = calloutResponse.endpoint;
        jsonLog.Fecha_Envio__c = Datetime.now();
        jsonLog.json__c = calloutResponse.request;
        jsonLog.Response_JSON__c = calloutResponse.response;

        return jsonLog;
    }

}