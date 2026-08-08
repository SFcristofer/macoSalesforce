public class QBInvoiceLinePayload {
    public String DetailType {set; get;}
    public String Amount {set; get;}
    public String Description {set; get;}    
    public QBInvoiceItemDetailPayload SalesItemLineDetail {set; get;}

    public QBInvoiceLinePayload () {
        DetailType = 'SalesItemLineDetail';
    }

}