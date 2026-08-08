public class OportunidadCerrarParcialmente {

    private String ERROR_MSG = 'No se puede cerrar la Oportunidad ya que no tiene ningún pedido asociado';

    public Opportunity originalOpportunity {set; get;}
    public Opportunity clonedOpportunity {set; get;}
    public List<OpportunityLineItem> oppLineItemsCloned {set; get;}
    public List<OpportunityLineItem> oppLineItemsOrig {set; get;}
    public List<SplitOppLineItem> splitOppLineItemsOrig {set; get;}    
    public Boolean noOrders {set; get;}
    public Map<Id, List<String>> prodsInProformaNOOrder {get;set;}
    public Map<Id, List<String>> prodsInProformaWOrder {get;set;}
    private SplitOpportunityController splitOppCtrl;

    public OportunidadCerrarParcialmente(ApexPages.StandardController stdController) {
        originalOpportunity = (Opportunity)stdController.getRecord();
        splitOpportunity();
        if(noOrders) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ERROR_MSG));
        }
    }

    public void splitOpportunity() {
        splitOppCtrl = new SplitOpportunityController(originalOpportunity.Id);
        System.debug('Original Opp Id [' + originalOpportunity.Id + ']');
        splitOppCtrl.splitOpportunities();
        clonedOpportunity = splitOppCtrl.clonedOpportunity;
        oppLineItemsOrig = splitOppCtrl.oppLineItems;
        splitOppLineItemsOrig = splitOppCtrl.splitOppLineItems;
        oppLineItemsCloned = splitOppCtrl.oppLineItemsCloned;
        System.debug('opp line items [' + splitOppCtrl.oppLineItems.size() + ']');
        noOrders = splitOppCtrl.oppLineItems.size() == 0;
        prodsInProformaNOOrder = splitOppCtrl.prodsInProformaNOOrder;
        prodsInProformaWOrder = splitOppCtrl.prodsInProformaWOrder;
    }

    public PageReference saveChanges() {
        PageReference pageRef = new PageReference('/lightning/o/Opportunity/list');

        splitOppCtrl.originalOpportunity.Is_Split_Flag__c = true;
        update splitOppCtrl.originalOpportunity;

        delete splitOppCtrl.oppLineItemsOppClone;

        update splitOppCtrl.originalOpportunity;

        //update quantity in op line items
        update splitOppCtrl.oppLineItems;

        insert clonedOpportunity;

        //Upsert Studies & Update Proformas
        Map<Id, EstudioOportunidad__c> oldStudyToClone = splitOppCtrl.processStudies(clonedOpportunity.Id);
        splitOppCtrl.processProformas(clonedOpportunity.Id, oldStudyToClone);

        for(OpportunityLineItem oliCln : splitOppCtrl.oppLineItemsCloned) {
            oliCln.OpportunityId = clonedOpportunity.Id;
            if(oldStudyToClone.containsKey(oliCln.EstudioOportunidad__c)) {
                oliCln.EstudioOportunidad__c = oldStudyToClone.get(oliCln.EstudioOportunidad__c).Id;
           }
        }
        //VERIFY SPLITED PRODUCTS HAVE BEEN CLONED TOO
        insert oppLineItemsCloned;

        splitOppCtrl.originalOpportunity.Is_Split_Flag__c = false;
        update splitOppCtrl.originalOpportunity;        

        return pageRef;
    }


}