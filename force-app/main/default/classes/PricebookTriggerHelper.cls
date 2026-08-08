/**
*	Helper class for Pricebook.trigger
*	Version 1.0
*	@author lcosta@infolastic.com
*/
public class PricebookTriggerHelper {
    private list<Id> pbsToUpd;
    private map<Id, Pricebook2> newPbs;
    
    public PricebookTriggerHelper(map<Id, Pricebook2> newPbs, map<Id, Pricebook2> oldPbs){
    	pbsToUpd = new list<Id>();
    	this.newPbs = newPbs;
    	
    	for(Pricebook2 p : newPbs.values()){
    		if(p.Margen__c != oldPbs.get(p.Id).Margen__c){
    			pbsToUpd.add(p.Id);
    		}
    	}
    }
    
    /**
    *	Recalculates prices based on Pricebook Margen
    *
    *	Note: Review potential Gobernor Limits exceeded for 16,667+ Products. 
    */
    public void execute(){
        list<PricebookEntry> lpbe = [SELECT Id,
    									Product2Id,
    									Pricebook2Id,
    									Product2.CostoTotal2__c,
    									Pricebook2.Margen__c
    									FROM PricebookEntry
    									WHERE Pricebook2Id in :pbsToUpd];
    	for(PricebookEntry pbe : lpbe){
    		double margen = newPbs.get(pbe.Pricebook2Id).Margen__c / 100;
            pbe.UseStandardPrice = false;
            pbe.UnitPrice = pbe.Product2.CostoTotal2__c/ (1 - margen);
    	}
    	update lpbe;
    }
}