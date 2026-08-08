public class QBInvoiceItemDetailPayload {
    public String Qty {set; get;}
    public String UnitPrice {set; get;}
    public QBInvoiceItemRefPayload ItemRef {set; get;}
    public QBInvoiceItemAccRefPayload ItemAccountRef {set; get;}    

    public QBInvoiceItemDetailPayload() {
    }

}