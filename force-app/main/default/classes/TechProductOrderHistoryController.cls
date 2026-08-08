public with sharing class TechProductOrderHistoryController {
    
    @AuraEnabled(cacheable=true)
    public static List<PedidoLineItem__c> getOrderHistory(Id recordId) {
        return [
            SELECT Id, Quantity__c, PedidoDeCompra__r.Name, PedidoDeCompra__r.Nombre_Proveedor__c, CostoOrigen__c 
            FROM PedidoLineItem__c 
            WHERE Producto__c = :recordId
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}
