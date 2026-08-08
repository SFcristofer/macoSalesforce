public class QBJournalEntrySyncController {
    //Se envia una factura y se registra log y se actualiza factura
    public final static String SINGLE_MODE = 'Single';
    
    //Se envia una factura a QB. Se crea un objeto log y se actualiza el objeto factura
    //pero los objetos se regresan para su posterior procesamiento
    public final static String SF_BATCH_MODE = 'Batch';
    
    private static String ESTADO_ENVIO_QB = 'Contabilizada';
    private FacturaDeProveedor__c facturaProveedor;
    private QBCallout qbCallout;
    private String jsonLogName;
    //Modo de operacion, single o batch
    private String operationMode;
    public Boolean envioExitoso {set; get;}    

    public QBJournalEntrySyncController(FacturaDeProveedor__c factura, String mode) {
        facturaProveedor = factura;
        operationMode = mode;
        initController();
    }
    
    public QBJournalEntrySyncController(String idFactura, String mode) {
        facturaProveedor = QBDAO.getFacturaProveedorForJournal(idFactura, ESTADO_ENVIO_QB);
        operationMode = mode;
        initController();
    }
    
    private void initController() {
        jsonLogName = 'QBAddJournalEntry';
        envioExitoso = false;
        qbCallout = new QBJournalEntryInsertCallout('QBConfig');
    }
    
    public QBJournalSyncResult sendToQB() {
        Boolean isErrorResponse = false;
        QBCalloutResponse calloutResponse;
        QBJournalCreateResponse createJournalResponse;
        QBJournalSyncResult journalResult;
        JSON_LOG__c jsonLog;
        String idQBooksJE;
        
        System.debug('sending qb Journal ...');
        System.debug('[' + facturaProveedor.Id + '] [' + facturaProveedor.Name + '] [' + facturaProveedor.Estado__c + ']');
        
        journalResult = new QBJournalSyncResult();
        
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
            journalResult.jsonLog = jsonLog;
        }

        if(!isErrorResponse) {
            createJournalResponse = (QBJournalCreateResponse)calloutResponse.responseObject;
            idQBooksJE = createJournalResponse.JournalEntry.Id;

            facturaProveedor.IdQboJournalEntry__c = idQBooksJE;

            if(operationMode.equals(SINGLE_MODE)) {
                update facturaProveedor;
            }
            if(operationMode.equals(SF_BATCH_MODE)) {
                journalResult.factura = facturaProveedor;
            }

            envioExitoso = true;
        }

        return journalResult;
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