/*
 * Acc Button to sync QB controller
 */
public class QBSyncAccountController {
    
    private Account account;
    private QBCallout qbCallout;
    private String jsonLogName;
    private String accountType;
    public String resultMessage {set; get;}
    public Boolean envioExitoso {set; get;}
    
    public QBSyncAccountController(ApexPages.StandardController stdController) {
        this(stdController.getId());
    }
    

    public QBSyncAccountController(String idAccount) {
        System.debug('Id Acc [' + idAccount + ']');
        envioExitoso = false;
        
        account = QBDAO.getAccount(idAccount);
        
        accountType = account.RecordType.DeveloperName;
        
        System.debug('Acount Type [' + accountType + ']');
        
        if(accountType.equals('Cliente')) {
            qbCallout = new QBCustomerInsertCallout('QBConfig');
            jsonLogName = 'QBAddCustomer';
        }
        if(accountType.equals('Proveedor')) {
            qbCallout = new QBVendorInsertCallout('QBConfig');
            jsonLogName = 'QBAddVendor';
        }
        resultMessage = '';
    }

    
    public PageReference syncQB() {
        Boolean isErrorResponse = false;
        QBCalloutResponse calloutResponse;
        
        QBCustomerCreateResponse createCustomerResponse;
        QBVendorCreateResponse createVendorResponse;
                
        String idQBooks;
        
        JSON_LOG__c jsonLog;
        
        System.debug('sending qb XXXXXXXXXXX ...');
        System.debug('[' + account.Id + '] [' + account.Name + '] [' + account.RecordType.DeveloperName + '] [' + account.Estado__c + ']');
        
        if(qbCallout != null) {
           calloutResponse = qbCallout.executeCallout(account);
           System.debug('QBCR CTRLR: ' + calloutResponse.response);
               
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
               if(accountType.equals('Cliente')) {
                   createCustomerResponse = (QBCustomerCreateResponse)calloutResponse.responseObject;
                   idQBooks = createCustomerResponse.Customer.Id;           
               }
           
               if(accountType.equals('Proveedor')) {
                   createVendorResponse = (QBVendorCreateResponse)calloutResponse.responseObject;
                   idQBooks = createVendorResponse.Vendor.Id;
               }
           
               account.IdQbo__c = idQBooks;
               update account;
               resultMessage = 'Register sent successfully to QBO';
               envioExitoso = true;
           } else {
               resultMessage = 'QBO Error. Please, contact your administrator';
           } 
        }
        return null;
    }
}