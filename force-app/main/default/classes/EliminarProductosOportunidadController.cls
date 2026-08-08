public class EliminarProductosOportunidadController {

    public List<OPLIWrapper> oppLIWrapperList {set; get;}
    public Opportunity opp {set; get;}

    public EliminarProductosOportunidadController (ApexPages.StandardController stdController) {
        String idOpportunity;
        OPLIWrapper oliWrapper;
        List<OpportunityLineItem> oppLineItems;
     
        oppLIWrapperList = new List<OPLIWrapper>();

        idOpportunity = ApexPages.currentPage().getParameters().get('id');
        opp = DOBrandsDAO.getOpportunityMP(idOpportunity);

        if(opp != null) {
            oppLineItems = opp.OpportunityLineItems;
        }

        for(OpportunityLineItem oppli : oppLineItems) {
            oliWrapper = new OPLIWrapper(oppli);
            oppLIWrapperList.add(oliWrapper);
        }
        
    }


    public PageReference deleteOppLineItems() {
        List<String> prodIds;
        List<OpportunityLineItem> oliToDelete;

        oliToDelete = new List<OpportunityLineItem>();
 
        //Get original opp line items id's list
        for(OPLIWrapper ooliw : oppLIWrapperList) {
            if(ooliw.selected) {
                oliToDelete.add(ooliw.oli);
                System.debug('OLI [' + ooliw.oli.Id + ']');
            }
        }

        delete oliToDelete;
        System.debug('Deleted');
        return null;
    }
    

    class OPLIWrapper {
        public OpportunityLineItem oli {set; get;}
        public Boolean selected {get;set;}

        public OPLIWrapper(OpportunityLineItem poli) {
            oli = poli;
        }
    }


}