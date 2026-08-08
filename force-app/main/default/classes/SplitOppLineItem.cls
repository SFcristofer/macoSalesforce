public class SplitOppLineItem {

    public OpportunityLineItem oppLI {set; get;}
    public List<String> proformaOrderNames {set; get;}


    public SplitOppLineItem(OpportunityLineItem poppoli) {
        oppLI = poppoli;
    }
}