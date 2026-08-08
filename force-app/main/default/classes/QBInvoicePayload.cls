public class QBInvoicePayload {
    //public String TotalAmt {set; get;}
    public QBInvoiceCustomerRefPayload CustomerRef {set; get;}
    public List<QBInvoiceLinePayload> Line {set; get;}
    public String TxnDate {set; get;}
    public String DueDate {set; get;}
    public String DocNumber {set; get;}

    public QBInvoicePayload() {
    }
 
}