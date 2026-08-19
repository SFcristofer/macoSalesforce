/**
 * QB Call - Update Bill
 */
public class QBBillUpdateCallout extends QBCallout {

    /*
     * metadataName - Check QBRESTConfiguration__mdt
     */
    public QBBillUpdateCallout(String metadataName) {
        super(metadataName, QBCallout.HTTP_METHOD_POST);
        QB_RESOURCE_NAME = 'bill';
    }

    public override String buildPayload(Object param) {
        QBBillUpdatePayload objPayload;
        QBBillVendorRefPayload vendorRef;
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
        
        objPayload = new QBBillUpdatePayload();
        vendorRef = new QBBillVendorRefPayload();
        lines = new List<QBBillLinePayload>();
         
        objPayload.VendorRef = vendorRef;
        objPayload.Line = lines;
        objPayload.Id = factura.IdQbo__c;
        objPayload.SyncToken = factura.QB_SyncToken__c;
        objPayload.DueDate = String.valueOf(factura.FechaVencimiento__c);
        objPayload.TxnDate = String.valueOf(factura.FechaDeFactura__c);//yyyy-mm-dd
        
        for(ItemDeFacturaDeProveedor__c itemFactura : itemsFactura) {
            itemAccRef = new QBBillLineAccountPayload();
            itemAccRef.AccountRef = accRef;
            
            line = new QBBillLinePayload();
            line.Description = itemFactura.Descripcion__c;
            line.Amount = String.ValueOf(itemFactura.Total__c);
            line.AccountBasedExpenseLineDetail = itemAccRef;
            lines.add(line);
        }

        vendorRef.value = factura.Proveedor__r.IdQbo__c;
        
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
        System.debug('CALL UPD RESULT[' + response + ']');

        if(response == null) {
            return 'error: QB bad response, please verify the log and contact to your administrator';
        }

        try {
            responseQB = (QBBillCreateResponse)JSON.deserialize(response, QBBillCreateResponse.class);
            System.debug('CALL UPD RESULT RESP[' + responseQB + ']');
            if(responseQB.Bill == null) {
                return 'error: QB bad response in update bill operation.Verify the log and contact your administrator';
            }
            if(responseQB.Bill.Id == null) {
                return 'error: QB bad response in update bill operation. Id param. Verify the log and contact your administrator';
            }
        } catch(JSONException je) {
            System.debug(je.getMessage());
            return 'error: QB bad response ' + je.getMessage() + '. Contact your administrator';
        }

        return responseQB;
    }

}