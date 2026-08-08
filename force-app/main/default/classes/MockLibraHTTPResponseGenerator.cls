@isTest
global class MockLibraHTTPResponseGenerator implements HttpCalloutMock {
    private String type;
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

    public MockLibraHTTPResponseGenerator(String ptype) {
        type = ptype;
    }

    global HTTPResponse respond(HTTPRequest req) {
       HttpResponse res = new HttpResponse();
       res.setHeader('Content-Type', 'application/json');
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