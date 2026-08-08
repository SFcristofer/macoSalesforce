public class OpportunityChangeHandler {

    public OpportunityChangeHandler() {

    }

    public Opportunity cloneOpportunityFromData(String idOp, String idPlanificacion, String oppName) {
        Opportunity originalOpp;
        Opportunity oppToBeCloned;

        originalOpp = OpportunityDAO.getClonedOpportunity(idOp);
        oppToBeCloned = originalOpp.clone(false, true);
        oppToBeCloned.Name = oppName;
        oppToBeCloned.PlanificacionComercial__c = idPlanificacion;

        insert oppToBeCloned;
        System.debug('Opp cloned ID[' + oppToBeCloned.Id + '] Name[' + oppToBeCloned.Name + ']');
        return oppToBeCloned;
    }
}