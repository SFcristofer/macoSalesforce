/**
*   Helper class for OpportunityLineItem.trigger
*   Older version backed up in Do-Brands/backups
*
*   New version do not allow edition of OpportunityLineItems which have been sent for Compras Validation
*
*   ver 3.0 Only Used for FieldHistoryTracking
*/
public class OLITriggerHelper {
    public static final String B4INS = 'b4ins';
    public static final String INS = 'ins';
    public static final String UPD = 'upd';
    public static final String DEL = 'del';
    
    private list<OpportunityLineItem> candidates;
    private map<Id, OpportunityLineItem> oldOLIs;
    
    private map<Id, String> prodIdToName;

    private set<Id> oppIds;
    private String oper;
    
    private static final String CREATED = '{U} agregó el producto {0}: {1} unidades, a ${2} por unidad';
    private static final String QTY_CH = '{U} modificó la cantidad del producto {0}: Antes {1} -> NUEVA CANTIDAD: {2}';
    private static final String PRICE_CH = '{U} modificó el precio del producto {0}: Antes {1} -> NUEVO PRECIO: {2}';
    private static final String DELETED = '{U} eliminó el producto {0} de la Propuesta';
   
    private static final String CREATED_NAME = 'Nuevo';
    private static final String CHANGED_NAME = 'Modificado';
    private static final String DELETED_NAME = 'Eliminado';

    private static boolean run = true;
    public static boolean runOnce(){
    if(run){
     run=false;
     return true;
    }else{
        return run;
    }
    }
    
    public static void resetRunForTesting(){
        run=true;
    }
    
    public OLITriggerHelper(list<OpportunityLineItem> olis, map<Id, OpportunityLineItem> oldOLIs, String oper){
        this.oper = oper;
        this.oldOLIs = oldOLIs;

        System.debug('OLITriggerHelper oper [' + oper + ']');
        System.debug('map old [' + this.oldOLIs + ']');
        
        candidates = new list<OpportunityLineItem>();
        set<Id> prodIds = new set<Id>();

        if(oper == B4INS) {
            candidates = olis;
        }else if(oper == INS){
            //All items which have a EstudioOportunidad linked get added
            for(OpportunityLineItem oli : olis){
                if(oli.EstudioOportunidad__c != null){
                    candidates.add(oli);
                    prodIds.add(oli.Product2Id);
                }
            }
        }else if(oper == DEL){
            //All deleted items which have an EstudioOportunidad linked get added
            for(OpportunityLineItem oli : oldOLIs.values()){
                if(oli.EstudioOportunidad__c != null){
                    candidates.add(oli);
                    prodIds.add(oli.Product2Id);
                }
            }
        }else if(oper == UPD){
            for(OpportunityLineItem oli : olis){
                if(oli.EstudioOportunidad__c != null &&
                    (oli.Quantity != oldOlis.get(oli.Id).Quantity 
                      || oli.UnitPrice != oldOlis.get(oli.Id).UnitPrice)){
                    candidates.add(oli);
                    prodIds.add(oli.Product2Id);
                }
            }
        }

        prodIdToName = new map<Id, String>();
        for(Product2 p : [SELECT Id, 
                                Name
                                FROM Product2
                                WHERE Id in :prodIds]){
            prodIdToName.put(p.Id, p.Name);
        }                     
    }
    
    public void execute(){
        if(oper == B4INS) {
            assingLatestPrice(candidates);
        } else if(oper != INS) {
            if(runOnce()) {
                system.debug(' oper [' + oper + ']');                
                system.debug('Entro la primera vez [' + this.oldOLIs + ']');
                list<Custom_FieldHistoryTracking__c> historyTracks = new list<Custom_FieldHistoryTracking__c>();
                if(oldOLIs != null)
                {
                    for(OpportunityLineItem oli : candidates){
                        historyTracks.add(createHistoryTrack(oper, oli, oldOLIs.get(oli.Id)));
                    }
                    insert historyTracks;
                }
            }
        }
    }

    private Custom_FieldHistoryTracking__c createHistoryTrack(String oper, OpportunityLineItem oldOLI, OpportunityLineItem newOLI){
        Custom_FieldHistoryTracking__c track = new Custom_FieldHistoryTracking__c();
        String description = '';
        String replaceString;
        boolean priceChanged = false;
        if(oper == INS){
            track.Name = CREATED_NAME;
            description = CREATED.replace('{1}', String.valueOf(newOLI.Quantity)).replace('{0}', String.valueOf(newOLI.UnitPrice));
        }else if(oper == UPD){
            track.Name = CHANGED_NAME;
            if(oldOLI.UnitPrice != newOLI.UnitPrice){
                priceChanged = true;
                System.debug('oliup[' + oldOLI.UnitPrice + '] [' + newOLI.UnitPrice + ']');
                if(newOLI.UnitPrice == null)
                {
                   replaceString = 'NA';
                }
                else
                {
                    replaceString = String.valueOf(newOLI.UnitPrice);
                }

                description = PRICE_CH.replace('{1}', String.valueOf(oldOLI.UnitPrice)).replace('{2}', replaceString);
            }
            if(oldOLI.Quantity != newOLI.Quantity){
                if(priceChanged){
                    //Avoid duplication of User Name & Product when including 2 messages
                    description += QTY_CH.replace('{U}', ', también').replace('{0}', '');
                }else{
                    description += QTY_CH;
                }
                description = description.replace('{1}', String.valueOf(oldOLI.Quantity)).replace('{2}', String.valueOf(newOLI.Quantity));
            }
        }else{
            track.Name = DELETED_NAME;
            description = DELETED;
        }
        String prodName = newOLI == null ? prodIdToName.get(oldOLI.Product2Id) : prodIdToName.get(newOLI.Product2Id);
        Id estudioId = newOLI == null ? oldOLI.EstudioOportunidad__c : newOLI.EstudioOportunidad__c;
        description = description.replace('{U}', UserInfo.getFirstName() + ' ' + UserInfo.getLastName() ).replace('{0}', prodName);
        track.Descripcion__c = description;
        track.EstudioOportunidad__c = estudioId;
        return track;
    }

    /**
     * Given a list of OpportunityLineItems gets the Ids of the accounts linked to the Opportunities
     * Returns a map with the Opportunity Id as key and the Account Id as value
     */
    private Map<Id, Id> getAccountForOpps(List<OpportunityLineItem> loli) {
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Id> result = new Map<Id, Id>();
        for(OpportunityLineItem oli : loli) {
            oppIds.add(oli.OpportunityId);
        }
        for(Opportunity o : [SELECT Id,
                                AccountId
                                FROM Opportunity
                                WHERE Id IN :oppIds]) {
            result.put(o.Id, o.AccountId);
        }
        return result;
    }

    /**
     * Given a list of OpportunityLineItems, gets the base product ids for the products in the list and returns a map
     * with the non-base product as key and the base product as the value
     */
    private Map<Id, Id> getBaseProductForProds(List<OpportunityLineItem> loli) {
        Set<Id> prodIds = new Set<Id>();
        Map<Id, Id> result = new Map<Id,Id>();
        for(OpportunityLineItem oli : loli) {
            prodIds.add(oli.Product2Id);
        }
        for(Product2 p : [SELECT Id,
                            ProductoBase__c,
                            ProductoDeFabrica__r.ProductoBase__c
                            FROM Product2
                            WHERE Id IN :prodIds]) {
            if(p.ProductoBase__c != null) {
                result.put(p.Id, p.ProductoBase__c);
            } else if(p.ProductoDeFabrica__r.ProductoBase__c != null) {
                result.put(p.Id, p.ProductoDeFabrica__r.ProductoBase__c);
            }
        }
        return result;
    }

    /**
     * Given a list of Account Ids and a list of Base Product Ids fetches the Opportunity Line Items 
     * from Closed Won Opportunities that match those parameters ordered by date desc and 
     * returns a map with AccountIdBaseProdId as key and the latest price for the pair
     * (if the product was previously bought by the account)
     */
    private Map<String, Decimal> getLatestPrices(List<Id> accountIds, List<Id> baseProductIds) {
        //convert lists to sets
        Set<Id> accIds = new Set<Id>(AccountIds);
        Set<Id> bProdIds = new Set<Id>(BaseProductIds);
        Map<String, Decimal> result = new Map<String, Decimal>();
        for(OpportunityLineItem oli : [SELECT UnitPrice,
                                            Opportunity.AccountId,
                                            Product2.ProductoBase__c,
                                            Product2.ProductoDeFabrica__r.ProductoBase__c
                                            FROM OpportunityLineItem
                                            WHERE Opportunity.isClosed = true
                                            AND Opportunity.isWon = true
                                            AND Opportunity.AccountId IN :accountIds
                                            AND (Product2.ProductoBase__c IN :baseProductIds
                                            OR Product2.ProductoDeFabrica__r.ProductoBase__c IN :baseProductIds)
                                            ORDER BY CreatedDate DESC]) {
            if(oli.Product2.ProductoBase__c != null) {
                if(!result.containsKey((String)oli.Opportunity.AccountId + (String)oli.Product2.ProductoBase__c)) {
                    result.put((String)oli.Opportunity.AccountId + (String)oli.Product2.ProductoBase__c, oli.UnitPrice);
                }
            } else if(oli.Product2.ProductoDeFabrica__r.ProductoBase__c != null) {
                if(!result.containsKey((String)oli.Opportunity.AccountId + (String)oli.Product2.ProductoDeFabrica__r.ProductoBase__c)) {
                    result.put((String)oli.Opportunity.AccountId + (String)oli.Product2.ProductoDeFabrica__r.ProductoBase__c, oli.UnitPrice);
                }
            }
        }
        return result;
    }

    /**
     * Assigns the latest price for an OpportunityLineItem if the same account bought the same product
     * in the past
     */
    private void assingLatestPrice(List<OpportunityLineItem> newItems) {
        Map<Id, Id> oppToAcc = getAccountForOpps(newItems);
        Map<Id, Id> nonBaseToBaseProd = getBaseProductForProds(newItems);
        Map<String, Decimal> latestPrices = getLatestPrices(oppToAcc.values(), nonBaseToBaseProd.values());
        for(OpportunityLineItem oli : newItems) {
            oli.Ultimo_Precio__c = latestPrices.get((String)oppToAcc.get(oli.OpportunityId) + (String)nonBaseToBaseProd.get(oli.Product2Id));
        }
    }
}