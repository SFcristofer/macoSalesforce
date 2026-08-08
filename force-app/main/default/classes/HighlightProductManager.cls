/**
 * Provides methods for defining if a product should be highlighted
 * Possible highlights are:
 * > New
 * > BestSeller In-n-Out
 * > BestSeller Global
 */
public class HighlightProductManager {
    public static final String PRODUCTO_BASE_RT = 'Producto';
    /** 
     *  Filters 10 newest products which have been created in the last 3 months for each product class  
    */
    public static Map<Id, Boolean> getHighlightedAsNew(){
        Map<Id, Boolean> result = new Map<Id, Boolean>();
        Integer i = 0;
        String previousClass = '';
        for(Product2 p : [SELECT Id,
                                Clase__c
                                FROM Product2
                                WHERE CreatedDate > :Date.today().addMonths(-3)
                                AND RecordType.DeveloperName = :PRODUCTO_BASE_RT
                                ORDER BY Clase__c, CreatedDate DESC]) {
            if(p.Clase__c == previousClass) {
                if (i < 10) {
                    result.put(p.Id, true);
                }
            } else {
                i = 0;
                previousClass = p.Clase__c;
                result.put(p.Id, true);
            }
            i++;
        }
        return result;
    }

    /** 
     *  Builds a map for all the products marked as "Best Seller Global"
    */
    public static Map<Id, Boolean> getBestSellerGlobal(){
        Map<Id, Boolean> result = new Map<Id, Boolean>();
        for(Product2 p : [SELECT Id
                                FROM Product2
                                WHERE RecordType.DeveloperName = :PRODUCTO_BASE_RT
                                AND Best_Seller_Global__c = true]) {
            result.put(p.Id, true);
        }
        return result; 
    }

    /** 
     *  Builds a map for all the products marked as "Best Seller In and Out"
    */
    public static Map<Id, Boolean> getBestSellerInNOut(){
        Map<Id, Boolean> result = new Map<Id, Boolean>();
        for(Product2 p : [SELECT Id
                                FROM Product2
                                WHERE RecordType.DeveloperName = :PRODUCTO_BASE_RT
                                AND Best_Seller_In_and_Out__c = true]) {
            result.put(p.Id, true);
        }
        return result;
    }
}