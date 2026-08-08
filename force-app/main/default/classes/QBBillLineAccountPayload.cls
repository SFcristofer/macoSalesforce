public class QBBillLineAccountPayload {
    public String BillableStatus;
    public QBBillAccountRefPayload AccountRef {set; get;}
    
    public QBBillLineAccountPayload() {
        BillableStatus = 'NotBillable';
    }
}