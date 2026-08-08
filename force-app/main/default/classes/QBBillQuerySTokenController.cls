public class QBBillQuerySTokenController {
    private static String ESTADO_QUERY_QB = 'Contabilizada';
    private static String ESTADO_PAGADA_SF = 'Pagada';
    private static String ESTADO_CANCEL_SF = 'Cancelada';
    private static String BILL_VOID_QB = 'Voided';

    private List<FacturaDeProveedor__c> facturasProveedor;
    private QBCallout qbCallout;
    private String jsonLogName;
    public Boolean successfulBillsUpdate {set; get;}


    public QBBillQuerySTokenController() {
        facturasProveedor = QBDAO.getFacturaProveedorByEstado(ESTADO_QUERY_QB);
        initController();
    }
    
    public QBBillQuerySTokenController(List<FacturaDeProveedor__c> facturas) {
        facturasProveedor = facturas;
        initController();
    }


    private void initController() {
        jsonLogName = 'QBQueryBill';
        successfulBillsUpdate = false;
        qbCallout = new QBBillQueryCallout('QBConfig', QBBillQueryCallout.QUERY_SYNCTOKEN);
    }
    
    public String sendToQB() {
        Boolean isErrorResponse = false;
        QBCalloutResponse calloutResponse;
        QBBillQueryResponse billQueryResponse;
        QBBillQueryResponseList qrList;
        List<QBBillQueryResponseBill> billsResponse;
        List<FacturaDeProveedor__c> facturasToUpdate;
        Map<String, QBBillQueryResponseBill> mapBillsResponse;
        QBBillQueryResponseBill billQB;
        
        JSON_LOG__c jsonLog;
        
        System.debug('Query bills ...');
        System.debug('no. facturas proveedor[' + facturasProveedor.size() + ']');
        
        mapBillsResponse = new Map<String, QBBillQueryResponseBill>();
        facturasToUpdate = new List<FacturaDeProveedor__c>();
        
        calloutResponse = qbCallout.executeCallout(facturasProveedor);
        System.debug('QBQB CTRLR: ' + calloutResponse.response);
               
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
            billQueryResponse = (QBBillQueryResponse)calloutResponse.responseObject;
            
            if(billQueryResponse != null) {
                qrList = billQueryResponse.QueryResponse;
                if(qrList != null) {
                    billsResponse = qrList.Bill;
                    for(QBBillQueryResponseBill bqr : billsResponse) {
                        mapBillsResponse.put(bqr.Id, bqr);
                    }
                }
            }

            for(FacturaDeProveedor__c fproveedor : facturasProveedor) {
                billQB = mapBillsResponse.get(fproveedor.IdQbo__c);
                if(billQB != null) {
                    System.debug('fproveedorIdQbo[' + fproveedor.IdQbo__c + '] billId[' + billQB.Id + '] Balance[' + billQB.Balance + '] SyncToken[' + billQB.SyncToken + ']');
                    fproveedor.QB_SyncToken__c = billQB.SyncToken;
                    facturasToUpdate.add(fproveedor);                    
                }
            }
            update facturasToUpdate;
            
            successfulBillsUpdate = true;
        }

        return null;
    }

}