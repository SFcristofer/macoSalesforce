/**
 * Handles the PlanificacionComercial trigger's logic
 */
public class PlanificacionComercialTriggerHelper {
    private static final String NEG_OPP_NAME = 'Penalización por exceso de aportaciones';
    private static final String NEG_OPP_CMPG = 'Cierre de Año';
    private List<PlanificacionComercial__c> newRecords;
    private Map<Id, PlanificacionComercial__c> oldMap;
    public PlanificacionComercialTriggerHelper(List<PlanificacionComercial__c> newRecords, 
                                                                    Map<Id, PlanificacionComercial__c> oldMap) {
        this.newRecords = newRecords;
        this.oldMap = oldMap;
    }

    public void afterUpdate() {
        Map<Id, PlanificacionComercial__c> changedPlans = new Map<Id, PlanificacionComercial__c>();
        for(PlanificacionComercial__c pc : newRecords) {
            if(pc.AportacionesPendientes__c != oldMap.get(pc.Id).AportacionesPendientes__c) {
                changedPlans.put(pc.Id, pc);
            }
        }
        Map<Id, Opportunity> accIdToNegOpp = new Map<Id,Opportunity>();
        List<Opportunity> lo = [SELECT  Id,
                                        AccountId
                                        FROM Opportunity
                                        WHERE Name = :NEG_OPP_NAME
                                        AND PlanificacionComercial__c IN :changedPlans.keySet()];
        for(Opportunity o : lo) {
            accIdToNegOpp.put(o.AccountId, o);
        }    
        List<Opportunity> negOpplist = new List<Opportunity>();
        Opportunity negOpp;
        for(PlanificacionComercial__c pc : changedPlans.values()) {
            if(!accIdToNegOpp.containsKey(pc.Cuenta__c)) {
                negOpp = new Opportunity(Name = NEG_OPP_NAME,
                                            CloseDate = Date.today(),
                                            StageName = 'Cerrada/Ganada',
                                            Seguimiento_de_Reposici_n__c = 'No',
                                            Campana__c = NEG_OPP_CMPG,
                                            AccountId = pc.Cuenta__c,
                                            PlanificacionComercial__c = pc.Id);
            } else {
                negOpp = accIdToNegOpp.get(pc.Cuenta__c);
            }
            if(pc.AportacionesPendientes__c < 0) {
                negOpp.Amount =  pc.AportacionesPendientes__c;
            } else {
                negOpp.Amount = 0;
            }
            negOppList.add(negOpp);
        }
        upsert negOppList;
    }
}