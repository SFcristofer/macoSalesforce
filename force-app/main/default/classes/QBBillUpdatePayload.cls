public class QBBillUpdatePayload {
    public List<QBBillLinePayload> Line {set; get;}
    public QBBillVendorRefPayload VendorRef {set; get;}
    public String Id {set; get;}
    public String SyncToken {set; get;}
    public String DueDate {set; get;}
    public String TxnDate {set; get;}

    public QBBillUpdatePayload() {
    }

}