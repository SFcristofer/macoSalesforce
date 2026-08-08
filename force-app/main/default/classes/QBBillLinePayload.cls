public class QBBillLinePayload {
    public String Description {set; get;}
    public String DetailType {set; get;}
    public String Amount {set; get;}
    public QBBillLineAccountPayload AccountBasedExpenseLineDetail {set; get;}

    public QBBillLinePayload() {
        DetailType = 'AccountBasedExpenseLineDetail';
    }

}