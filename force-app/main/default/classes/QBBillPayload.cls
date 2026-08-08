public class QBBillPayload {
    public List<QBBillLinePayload> Line {set; get;}
    public QBBillVendorRefPayload VendorRef {set; get;}
    public QBBillAPAccRefPayload  APAccountRef {set; get;}    
    
    public String DueDate {set; get;}
    public String TxnDate {set; get;}
    public String DocNumber {set; get;}

    public QBBillPayload() {
    }

}