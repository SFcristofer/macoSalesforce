public class QBJournalPayloadEntry {
    public String DocNumber {set; get;}
    public String PrivateNote {set; get;}
    public String TxnDate {set; get;}
    public List<QBJournalPayloadEntryLine> Line {set; get;}
}