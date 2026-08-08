public class QBBillSyncController {
    //Se envia una factura y se registra log y se actualiza factura
    public final static String SINGLE_MODE = 'Single';
    
    //Se envia una factura a QB. Se crea un objeto log y se actualiza el objeto factura
    //pero los objetos se regresan para su posterior procesamiento
    public final static String SF_BATCH_MODE = 'Batch';
    
    private static String ESTADO_ENVIO_QB = 'Creada';
    private static String ESTADO_ENVIO_QB_EXITOSO = 'Contabilizada';
    private FacturaDeProveedor__c facturaProveedor;
    private QBCallout qbCallout;
    private String jsonLogName;
    //Modo de operacion, single o batch
    private String operationMode;
    public Boolean envioExitoso {set; get;}    

    public QBBillSyncController(FacturaDeProveedor__c factura, String mode) {
        facturaProveedor = factura;
        operationMode = mode;
        initController();
    }
    
    public QBBillSyncController(String idFactura, String mode) {
        facturaProveedor = QBDAO.getFacturaProveedor(idFactura, ESTADO_ENVIO_QB);
        operationMode = mode;
        initController();
    }
    
    private void initController() {
        jsonLogName = 'QBAddBill';
        envioExitoso = false;
        qbCallout = new QBBillInsertCallout('QBConfig');
    }
    
    public QBBillSyncResult sendToQB() {
        Boolean isErrorResponse = false;
        QBCalloutResponse calloutResponse;
        QBBillCreateResponse createBillResponse;
        QBBillSyncResult billResult;
        JSON_LOG__c jsonLog;
        String idQBooks;
        
        System.debug('sending qb Bill ...');
        System.debug('[' + facturaProveedor.Id + '] [' + facturaProveedor.Name + '] [' + facturaProveedor.Estado__c + ']');
        
        billResult = new QBBillSyncResult();
        
        calloutResponse = qbCallout.executeCallout(facturaProveedor);
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
            billResult.jsonLog = jsonLog;
        }

        if(!isErrorResponse) {
            createBillResponse = (QBBillCreateResponse)calloutResponse.responseObject;
            idQBooks = createBillResponse.Bill.Id;

            facturaProveedor.IdQbo__c = idQBooks;
            facturaProveedor.Estado__c = ESTADO_ENVIO_QB_EXITOSO;

            if(operationMode.equals(SINGLE_MODE)) {
                update facturaProveedor;
            }
            if(operationMode.equals(SF_BATCH_MODE)) {
                billResult.factura = facturaProveedor;
            }

            envioExitoso = true;
        }

        return billResult;
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