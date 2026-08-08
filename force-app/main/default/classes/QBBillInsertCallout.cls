/**
 * QB Call - Insert Bill
 */
public class QBBillInsertCallout extends QBCallout {

    /*
     * metadataName - Check QBRESTConfiguration__mdt
     */
    public QBBillInsertCallout(String metadataName) {
        super(metadataName, QBCallout.HTTP_METHOD_POST);
        QB_RESOURCE_NAME = 'bill';
    }

    public override String buildPayload(Object param) {
        QBBillPayload objPayload;
        QBBillVendorRefPayload vendorRef;
        QBBillAPAccRefPayload apAccRef;
        
        List<QBBillLinePayload> lines;
        QBBillLinePayload line;

        QBBillAccountRefPayload accRef;
        QBBillLineAccountPayload itemAccRef;

        List<ItemDeFacturaDeProveedor__c> itemsFactura;
        String payload;
        FacturaDeProveedor__c factura;

        accRef = new QBBillAccountRefPayload();
        accRef.value = QB_BILL_ACC_REF;

        factura = (FacturaDeProveedor__c)param;
        itemsFactura = factura.ItemsDeFacturaDeProveedor__r;


        objPayload = new QBBillPayload();
        vendorRef = new QBBillVendorRefPayload();
        apAccRef = new QBBillAPAccRefPayload();
        apAccref.value = QB_BILL_AP_ACC_REF;
        lines = new List<QBBillLinePayload>();

        objPayload.VendorRef = vendorRef;
        objPayload.APAccountRef = apAccref;
                
        objPayload.Line = lines;
        objPayload.DueDate = String.valueOf(factura.FechaVencimiento__c);//yyyy-mm-dd
        objPayload.TxnDate = String.valueOf(factura.FechaDeFactura__c);//yyyy-mm-dd
        objPayload.DocNumber = factura.Name;

        for(ItemDeFacturaDeProveedor__c itemFactura : itemsFactura) {
            itemAccRef = new QBBillLineAccountPayload();
            itemAccRef.AccountRef = accRef;

            line = new QBBillLinePayload();
            line.Description = itemFactura.Descripcion__c;
            line.Amount = String.valueOf(itemFactura.Total__c);
            line.AccountBasedExpenseLineDetail = itemAccRef;
            lines.add(line);
        }

        vendorRef.value = factura.Proveedor__r.IdQbo__c;
        
        if(vendorRef.value == null) {
            throw new PGException('Factura Proveedor[' + factura.Name + '] Proveedor [' + factura.Proveedor__r.Name + '] field has not IDQB valid value [' + vendorRef.value + ']');
        }
        
        payload = JSON.serialize(objPayload);
        return payload;
    }

    public override String buildEndpoint(Object param) {
        //'callout:testQBNC/v3/company/9341451964358547/bill?minorversion=65'
        String endpoint;
        endpoint = SF_NAMEDC_SCHEMA + SF_NAMED_CREDENTIAL + QB_URI_CONTEXT + QB_COMPANY_ID + '/' + QB_RESOURCE_NAME;
        return endpoint;
    }


    public override Object processResponse(String response) {
        QBBillCreateResponse responseQB;
        System.debug('CALL RESULT[' + response + ']');

        if(response == null) {
            return 'error: QB bad response, please verify the log and contact to your administrator';
        }

        try {
            responseQB = (QBBillCreateResponse)JSON.deserialize(response, QBBillCreateResponse.class);
            if(responseQB.Bill == null) {
                return 'error: QB bad response in add bill operation.Verify the log and contact your administrator';
            }
            if(responseQB.Bill.Id == null) {
                return 'error: QB bad response in add bill operation. Id param. Verify the log and contact your administrator';
            }
        } catch(JSONException je) {
            System.debug(je.getMessage());
            return 'error: QB bad response ' + je.getMessage() + '. Contact your administrator';
        }


        return responseQB;
    }

}