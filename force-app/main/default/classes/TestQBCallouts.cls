@isTest
private class TestQBCallouts {


    @isTest static void testCreateQBCustomer() {

        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        Account cl = tu.getClienteCred();

        //AccountBatchLibra talc = new AccountBatchLibra(cl,'400','009800','1234');

        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('addQBCustomer'));
        Test.startTest();
        QBCallout callout = new QBCustomerInsertCallout('QBConfig');
        callout.executeCallout(cl);
        Test.stopTest();
    }


    @isTest static void testCreateQBVendor() {

        TestUtil tu = new TestUtil();
        tu.initOpportunitySplit();
        Account cl = tu.getClienteCred();

        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('addQBVendor'));
        Test.startTest();
        QBCallout callout = new QBVendorInsertCallout('QBConfig');
        callout.executeCallout(cl);
        Test.stopTest();
    }


    @isTest static void testQBCustomerResponse() {
        QBCustomerQueryResponseLine  qbcqrl = new QBCustomerQueryResponseLine ();
        qbcqrl.sparse = 'true';
        qbcqrl.Id = '123';
        qbcqrl.DisplayName = 'dpn';
        
        QBCustomersQueryResponseList qbqrl = new QBCustomersQueryResponseList();
        qbqrl.Customer.add(qbcqrl);
        
        QBCustomerQueryResponse qbcqr = new QBCustomerQueryResponse();
        qbcqr.QueryResponse = qbqrl;
    }


    @isTest static void testQBVendorResponse() {
        QBVendorQueryResponseLine qbvqrl = new QBVendorQueryResponseLine();
        qbvqrl.sparse = 'true';
        qbvqrl.Id = '123';
        qbvqrl.DisplayName = 'dpn';
        
        QBVendorsQueryResponseList qbqrl = new QBVendorsQueryResponseList();
        qbqrl.Vendor.add(qbvqrl);
        
        QBVendorQueryResponse qbcqr = new QBVendorQueryResponse();
        qbcqr.QueryResponse = qbqrl;
    }
    
    
    @isTest static void testQBInvoice() {
        FacturaDeCliente__c facturaCliente;
        QBInvoiceSyncController qbSyncCtrlr;

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaCliente('Enviada');
        
        facturaCliente = [SELECT Id,
                           Name,
                           Estado__c,
                           IdQbo__c,
                           Total__c,
                           FechaDeFactura__c,
                           FechaVencimiento__c,
                           Cliente__r.Parent.IdQbo__c,
                           (SELECT Id,
                                   Name,
                                   PrecioDeVenta__c,
                                   Descripcion__c,
                                   Total__c,
                                   Cantidad__c
                              FROM ItemsDeFacturaDeCliente__r)
                      FROM FacturaDeCliente__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('addQBInvoice'));
        Test.startTest();
        qbSyncCtrlr = new QBInvoiceSyncController(facturaCliente, QBInvoiceSyncController.SINGLE_MODE);
        //qbSyncCtrlr = new QBInvoiceSyncController(facturaCliente);
        qbSyncCtrlr.sendToQB();
        Test.stopTest();

    }


    @isTest static void testQBBill() {
        FacturaDeProveedor__c facturaProveedor;
        QBBillSyncController qbSyncCtrlr;

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaProveedor('Creada');
        
        facturaProveedor = [SELECT Id,
                                   Name,
                                   Estado__c,
                                   IdQbo__c,
                                   Total__c,
                                   FechaDeFactura__c,
                                   FechaVencimiento__c,
                                   Proveedor__r.IdQbo__c,
                                   (SELECT Id,
                                           Name,
                                           Descripcion__c,
                                           Total__c
                                      FROM ItemsDeFacturaDeProveedor__r)
                              FROM FacturaDeProveedor__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('addQBBill'));
        Test.startTest();
        //qbSyncCtrlr = new QBBillSyncController(facturaProveedor);
        qbSyncCtrlr = new QBBillSyncController(facturaProveedor, QBBillSyncController.SINGLE_MODE);
        qbSyncCtrlr.sendToQB();
        Test.stopTest();
    }
    
    
    @isTest static void testQBAddJournalEntry() {
        FacturaDeProveedor__c facturaProveedor;
        QBJournalEntrySyncController qbSyncCtrlr;

        TestQBUtil tqu = new TestQBUtil();
        tqu.initFacturaProveedor('Creada');
        
        facturaProveedor = [SELECT Id,
                                   Name,
                                   Estado__c,
                                   IdQbo__c,
                                   IdQboJournalEntry__c,
                                   JournalEntryCreadoEnQbo__c,
                                   QboJournalEntryNo__c,
                                   QboJournalEntryDescription__c,                                   
                                   Total__c,
                                   FechaDeFactura__c,
                                   FechaVencimiento__c,
                                   Proveedor__r.IdQbo__c,
                                   (SELECT Id,
                                           Name,
                                           Descripcion__c,
                                           Total__c
                                      FROM ItemsDeFacturaDeProveedor__r)
                              FROM FacturaDeProveedor__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('addQBJournal'));
        Test.startTest();
        //qbSyncCtrlr = new QBBillSyncController(facturaProveedor);
        qbSyncCtrlr = new QBJournalEntrySyncController(facturaProveedor, QBJournalEntrySyncController.SINGLE_MODE);
        qbSyncCtrlr.sendToQB();
        Test.stopTest();

    }
    
    
    
    @isTest static void testPedidoQB() {
        TestQBUtil tqu = new TestQBUtil();
        
        /*MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource(
            'callout:testQBNC/v3/company/9341451964358547/customer', '{"Customer": {"Id":"400","DisplayName":"PPP"}}');
        multimock.setStaticResource(
            'callout:testQBNC/v3/company/9341451964358547/vendor', '{"Vendor": {"Id":"400","DisplayName":"PPP"}}');
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');*/
        
        //private String addQBCustomer = '{"Customer": {"Id":"400","DisplayName":"PPP"}}';
        //private String addQBVendor = '{"Vendor": {"Id":"400","DisplayName":"PPP"}}';
        
        // Set the mock callout mode
        //Test.setMock(HttpCalloutMock.class, multimock);        
        
        Test.setMock(HttpCalloutMock.class, new QBMockHTTPResponseGenerator('addQBCustomer'));
        tqu.initPedidoCallQB();
    }
    

/*


*/

}