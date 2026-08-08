public class QBCustomersQueryResponseList {
    public List<QBCustomerQueryResponseLine> Customer {set; get;}
    
    public QBCustomersQueryResponseList() {
        Customer = new List<QBCustomerQueryResponseLine>();
    }
}