/**
 * QB Call - Insert invoice
 */
public class QBInvoiceInsertCallout extends QBCallout {

    /*
     * metadataName - Check QBRESTConfiguration__mdt
     */
    public QBInvoiceInsertCallout(String metadataName) {
        super(metadataName, QBCallout.HTTP_METHOD_POST);
        QB_RESOURCE_NAME = 'invoice';
    }

    public override String buildPayload(Object param) {
        QBInvoicePayload objPayload;
        QBInvoiceCustomerRefPayload customRef;
        List<QBInvoiceLinePayload> lines;
        QBInvoiceLinePayload line;
        QBInvoiceItemDetailPayload lineItemDetail;
        QBInvoiceItemRefPayload itemRefPyld;
        QBInvoiceItemAccRefPayload itemAccRefPyld;
        List<ItemDeFacturaDeCliente__c> itemsFactura;
        String payload;
        FacturaDeCliente__c factura;
        
        factura = (FacturaDeCliente__c)param;
        itemsFactura = factura.ItemsDeFacturaDeCliente__r;
        
        objPayload = new QBInvoicePayload();
        customRef = new QBInvoiceCustomerRefPayload();
        lines = new List<QBInvoiceLinePayload>();
         
        objPayload.CustomerRef = customRef;
        objPayload.Line = lines;
        objPayload.TxnDate = getFormatedDate(factura.FechaDeFactura__c);
        objPayload.DueDate = getFormatedDate(factura.FechaVencimiento__c);
        objPayload.DocNumber = factura.Name;
        
        for(ItemDeFacturaDeCliente__c itemFactura : itemsFactura) {
            lineItemDetail = new QBInvoiceItemDetailPayload();
            lineItemDetail.Qty = String.ValueOf(itemFactura.Cantidad__c);
            lineItemDetail.UnitPrice = String.ValueOf(itemFactura.PrecioDeVenta__c);
            
            itemRefPyld = new QBInvoiceItemRefPayload();
            itemRefPyld.value = QB_ITEM_REF;
            //itemRefPyld.name = 'Product';
            itemAccRefPyld = new QBInvoiceItemAccRefPayload();
            itemAccRefPyld.value = QB_ITEM_ACC_REF;
            //itemAccRefPyld.name = 'Sales';
            lineItemDetail.ItemRef = itemRefPyld;
            lineItemDetail.ItemAccountRef = itemAccRefPyld;
            
            line = new QBInvoiceLinePayload();
            line.Description = itemFactura.Descripcion__c;
            line.Amount = String.ValueOf(itemFactura.Total__c);
            line.SalesItemLineDetail = lineItemDetail;
            lines.add(line);
        }
        
        customRef.value = factura.Cliente__r.Parent.IdQbo__c;
        
        payload = JSON.serialize(objPayload);
        return payload;
    }

    public override String buildEndpoint(Object param) {
        //'callout:testQBNC/v3/company/9341451964358547/invoice?minorversion=65'
        String endpoint;
        endpoint = SF_NAMEDC_SCHEMA + SF_NAMED_CREDENTIAL + QB_URI_CONTEXT + QB_COMPANY_ID + '/' + QB_RESOURCE_NAME;
        return endpoint;
    }


    public override Object processResponse(String response) {
        QBInvoiceCreateResponse responseQB;
        System.debug('CALL RESULT[' + response + ']');

        if(response == null) {
            return 'error: QB bad response, please verify the log and contact to your administrator';
        }

        try {
            responseQB = (QBInvoiceCreateResponse)JSON.deserialize(response, QBInvoiceCreateResponse.class);
            if(responseQB.Invoice == null) {
                return 'error: QB bad response in add invoice operation.Verify the log and contact your administrator';
            }
            if(responseQB.Invoice.Id == null) {
                return 'error: QB bad response in add invoice operation. Id param. Verify the log and contact your administrator';
            }
        } catch(JSONException je) {
            System.debug(je.getMessage());
            return 'error: QB bad response ' + je.getMessage() + '. Contact your administrator';
        }
        return responseQB;
    }
    
    
    private String getFormatedDate(Date fecha) {
        String formatedDate;
        String[] tokens;
        String nonFormatedDate;
        
        if(fecha != null) {
            nonFormatedDate = fecha.toString();
            tokens = nonFormatedDate.split(' ');
            formatedDate = tokens[0];
        }
        return formatedDate;
    }
    
}