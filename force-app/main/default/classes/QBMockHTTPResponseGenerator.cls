@isTest
global class QBMockHTTPResponseGenerator implements HttpCalloutMock {
    private String type;
    private String addQBCustomer = '{"Customer": {"Id":"400","DisplayName":"PPP"}}';
    private String addQBVendor = '{"Vendor": {"Id":"400","DisplayName":"PPP"}}';
    private String addQBInvoice = '{"Invoice": {"Id":"400","TxnDate":"2014-09-19","DueDate":"2014-10-19","TotalAmnt": 362.07, "Deposit": 0, "Balance": 362.07, "DocNumber": "1037"}}';
    private String addQBBill = '{"Bill": {"Id":"400","TxnDate":"2014-09-19","DueDate":"2014-10-19","TotalAmnt": 362.07, "Balance": 362.07}}';
    private String addQBJournal = '{"JournalEntry": {"Id":"400","TxnDate":"2014-09-19"}}';    
    
    private String qryQBInvoiceCancelada = '{"QueryResponse": {"Invoice": [{"Id": "34","PrivateNote": "Voided","LinkedTxn": [],"Line": [],"CustomerRef": {"value": "29","name": "custTest"},"Balance": 0}],"startPosition": 1,"maxResults": 1,"totalCount": 1}}';
    private String qryQBInvoiceCobrada = '{"QueryResponse": {"Invoice": [{"Id": "34","LinkedTxn": [],"Line": [],"CustomerRef": {"value": "29","name": "custTest"},"Balance": 0}],"startPosition": 1,"maxResults": 1,"totalCount": 1}}';
    private String qryQBBillCancelado = '{"QueryResponse": {"Bill": [{"Id": "34","SyncToken": "2","PrivateNote": "Voided","LinkedTxn": [],"Line": [],"VendorRef": {"value": "29","name": "vendTest"},"Balance": 0}],"startPosition": 1,"maxResults": 1,"totalCount": 1}}';
    private String qryQBBillPagado = '{"QueryResponse": {"Bill": [{"Id": "34","SyncToken": "2","LinkedTxn": [],"Line": [],"VendorRef": {"value": "29","name": "vendTest"},"Balance": 0}],"startPosition": 1,"maxResults": 1,"totalCount": 1}}';

    private String cobros = '{"cobros": [{"codigo_empresa":"400","numero_factura":"342","ejercicio":"2019","importe_cobrado":"0","fecha_cobro":"21/03/2019 00:00:00"}]}';
    private String pagos = '{"pagos": [{"codigo_empresa":"400","numero_factura":"ABC0023","ejercicio":"2019","importe_pagado":"0","fecha_pago":"21/03/2019 00:00:00"}]}';
    private String altaCuenta = '{"status":"OK"}';
    private String altaCuentaError = '{"status":"ERROR", "errors":{"error_message":"error de mensaje"}}';    
    private String example = '{"example":"test"}';
    private String aws = '{"URL":"http://mitest.com"}';
    private String exchangeRate = '<gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">' +
                                  '<gesmes:subject>Reference rates</gesmes:subject>' +
                                  '<gesmes:Sender>' +
                                  '<gesmes:name>European Central Bank</gesmes:name>' +
                                  '</gesmes:Sender>' +
                                  '<Cube>' +
                                  '<Cube time="2020-03-27">' +
                                  '<Cube currency="USD" rate="1.0977"/>' +
                                  '</Cube>' +
                                  '</Cube>' +
                                  '</gesmes:Envelope>';

    public QBMockHTTPResponseGenerator(String ptype) {
        type = ptype;
    }

    global HTTPResponse respond(HTTPRequest req) {
       String[] tokens;
       String qbEndpoint;
       String qbResource;
       Integer tokensSize;
       
       qbEndpoint = req.getEndpoint();
       
       System.debug('Mock Endpoint [' + qbEndpoint + ']');
       
       if(qbEndpoint != null) {
           tokens = qbEndpoint.split('/');
           tokensSize = tokens.size();
           if(tokensSize >= 1) {
               qbResource = tokens[tokensSize - 1];               
           }
       }
       
       HttpResponse res = new HttpResponse();
       res.setHeader('Content-Type', 'application/json');
       
       //if(type.equals('addQBCustomer')) {
       if(qbResource.equals('customer')) {
           res.setBody(addQBCustomer);
       }

       //if(type.equals('addQBVendor')) {
       if(qbResource.equals('vendor')) {
           res.setBody(addQBVendor);
       }

       //if(type.equals('addQBInvoice')) {
       if(qbResource.equals('invoice')) {
           res.setBody(addQBInvoice);
       }

       //if(type.equals('addQBBill')) {
       if(qbResource.equals('bill')) {
           res.setBody(addQBBill);
       }

       if(qbResource.equals('journalentry')) {
           res.setBody(addQBJournal);
       }
       
       
       if(type.equals('invoiceCobrada')) {
           res.setBody(qryQBInvoiceCobrada);
       }
       if(type.equals('invoiceCancelada')) {
           res.setBody(qryQBInvoiceCancelada);
       }
       if(type.equals('billPagado')) {
           res.setBody(qryQBBillPagado);
       }
       if(type.equals('billCancelado')) {
           res.setBody(qryQBBillCancelado);
       }
       
       
       if(type.equals('example')) {
           res.setBody(example);
       }
       if(type.equals('cobros')) {
           res.setBody(cobros);
       }
       if(type.equals('pagos')) {
           res.setBody(pagos);
       }
       if(type.equals('altaCuenta')) {
           res.setBody(altaCuenta);
       }
       if(type.equals('altaCuentaError')) {
           res.setBody(altaCuentaError);
       }
       if(type.equals('aws')) {
           res.setBody(aws);
       }
       if(type.equals('exchangeRate')) {
           res.setBody(exchangeRate);
       }


       res.setStatusCode(200);
       res.setStatus('OK');
       return res;
    }
}