public class QBBillQueryController {
    private static String ESTADO_QUERY_QB = 'Contabilizada';
    private static String ESTADO_PAGADA_SF = 'Pagada';
    private static String ESTADO_CANCEL_SF = 'Cancelada';
    private static String BILL_VOID_QB = 'Voided';

    private List<FacturaDeProveedor__c> facturasProveedor;
    private QBCallout qbCallout;
    private String jsonLogName;
    public Boolean successfulBillsUpdate {set; get;}


    public QBBillQueryController() {
        facturasProveedor = QBDAO.getFacturaProveedorByEstado(ESTADO_QUERY_QB);
        initController();
    }
    
    public QBBillQueryController(List<FacturaDeProveedor__c> facturas) {
        facturasProveedor = facturas;
        initController();
    }


    private void initController() {
        jsonLogName = 'QBQueryBill';
        successfulBillsUpdate = false;
        qbCallout = new QBBillQueryCallout('QBConfig', QBBillQueryCallout.QUERY_BALANCE);
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
                    if(billsResponse != null) {
                        for(QBBillQueryResponseBill bqr : billsResponse) {
                            mapBillsResponse.put(bqr.Id, bqr);
                        }
                    }
                }
            }

            for(FacturaDeProveedor__c fproveedor : facturasProveedor) {
                billQB = mapBillsResponse.get(fproveedor.IdQbo__c);
                if(billQB != null) {
                    System.debug('fproveedorIdQbo[' + fproveedor.IdQbo__c + '] billId[' + billQB.Id + '] Balance[' + billQB.Balance + '] PrivateNote[' + billQB.PrivateNote + ']');
                    if((billQB.Balance.equals('0') && billQB.PrivateNote == null) || (billQB.Balance.equals('0') && billQB.PrivateNote != null && !billQB.PrivateNote.equals(BILL_VOID_QB))) {
                        System.debug('fproveedorIdQbo[' + fproveedor.IdQbo__c + '] PAGADA');
                        fproveedor.Estado__c = ESTADO_PAGADA_SF;
                        facturasToUpdate.add(fproveedor);
                    }
                    if(billQB.Balance.equals('0') && billQB.PrivateNote != null && billQB.PrivateNote.equals(BILL_VOID_QB)) {
                        System.debug('fproveedorIdQbo[' + fproveedor.IdQbo__c + '] CANCELADA');
                        fproveedor.Estado__c = ESTADO_CANCEL_SF;
                        facturasToUpdate.add(fproveedor);
                    }
                }
            }
            update facturasToUpdate;
            
            successfulBillsUpdate = true;
        }

        return null;
    }

}