public class OpportunityAWSPayload {
    public String id_op {set; get;}
    public String name_op {set; get;}
    public String fob_pr_r {set; get;}
    public String fob_pr_g {set; get;}
    public String fob_pr_b {set; get;}
    public String template_f {set; get;}
    public String s3_bucket {set; get;}
    public String s3_region {set; get;}
    public String font_name {set; get;}
    public String font_size {set; get;}
    public String test_items_to_proc {set; get;}    

    public List<OpportunityLineItemAWSPayload> items;

    public OpportunityAWSPayload() {
        items = new List<OpportunityLineItemAWSPayload>();
    }

}