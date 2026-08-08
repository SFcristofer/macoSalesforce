public class QBJournalPayloadEntryLineDetail {
    //Debit, Credit
    public String PostingType {set; get;}
    public QBJournalPayloadAccRef AccountRef {set; get;}
    public QBJournalPayloadEntity Entity {set; get;}
}