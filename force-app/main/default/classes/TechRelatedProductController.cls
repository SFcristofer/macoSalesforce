public with sharing class TechRelatedProductController {
    
    @AuraEnabled(cacheable=true)
    public static List<Product2> getRelatedProducts(Id recordId) {
        return [
            SELECT Id, Codigo_Proveedor__c, PrecioDeFabrica__c, Nombre_Fabrica__c 
            FROM Product2 
            WHERE ProductoBase__c = :recordId
        ];
    }
}