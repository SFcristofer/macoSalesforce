public class QBVendorsQueryResponseList {
    public List<QBVendorQueryResponseLine> Vendor {set; get;}
    
    public QBVendorsQueryResponseList() {
        Vendor = new List<QBVendorQueryResponseLine>();
    }
}