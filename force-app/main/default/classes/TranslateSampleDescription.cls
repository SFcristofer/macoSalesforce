public class TranslateSampleDescription {
    private Id srId;
    
    public TranslateSampleDescription(ApexPages.StandardController std){
    	srId = std.getId();
    }
    
    public PageReference translate(){
    	list<Muestra__c> lm = [SELECT Id,
    							Descripcion__c
    							FROM Muestra__c
    							WHERE Solicitud_de_Muestra__c = :srId];
    	for(Muestra__c m : lm){
			m.Description__c = TranslationService.translate(m.Descripcion__c);		
		}
		update lm;
		return new PageReference('/' + srId);
    }
    
}