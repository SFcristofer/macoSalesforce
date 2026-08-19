FacturaDeCliente__c factura = [SELECT Id, Name, Cliente__r.Parent.IdQbo__c, FechaDeFactura__c, FechaVencimiento__c, 
                                (SELECT Id, Cantidad__c, PrecioDeVenta__c, Descripcion__c, Total__c FROM ItemsDeFacturaDeCliente__r) 
                                FROM FacturaDeCliente__c 
                                WHERE Name = 'FC26070510' LIMIT 1];

QBInvoiceInsertCallout callout = new QBInvoiceInsertCallout('QBConfig');
String payload = callout.buildPayload(factura);
System.debug('PAYLOAD_DEBUG: ' + payload);
