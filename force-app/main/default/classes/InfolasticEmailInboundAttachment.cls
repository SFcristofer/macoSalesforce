public class InfolasticEmailInboundAttachment implements Comparable {
    public Messaging.InboundEmail.BinaryAttachment attachment {set; get;}
    public Boolean isPrincipal {set; get;}

    public InfolasticEmailInboundAttachment(Messaging.InboundEmail.BinaryAttachment pattachment) {
        attachment = pattachment;
        isPrincipal = false;
    }

    public Integer compareTo(Object compareTo) {
        InfolasticEmailInboundAttachment attToCompare = (InfolasticEmailInboundAttachment)compareTo;
        if(attachment.body.size() == attToCompare.attachment.body.size()) {
            return 0;
        }
        if(attachment.body.size() > attToCompare.attachment.body.size()) {
            return 1;
        }
        return -1;
    }
}