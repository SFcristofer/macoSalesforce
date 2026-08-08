public class QBJournalPayloadEntryLine {
    public String Description {set; get;}
    public String Amount {set; get;}
    public String DetailType {set; get;}
    public QBJournalPayloadEntryLineDetail JournalEntryLineDetail {set; get;}
    
    public QBJournalPayloadEntryLine() {
        DetailType = 'JournalEntryLineDetail';
    }
}