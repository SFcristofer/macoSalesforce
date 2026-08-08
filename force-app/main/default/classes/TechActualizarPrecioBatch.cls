public class TechActualizarPrecioBatch implements Database.Batchable<sObject> {
    private Set<Id> candBaseIds;

    public TechActualizarPrecioBatch(Set<Id> candBaseIds) {
        this.candBaseIds = candBaseIds;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id FROM Product2 WHERE Id IN :candBaseIds]);
    }

    public void execute(Database.BatchableContext BC, List<Product2> scope) {
        Set<Id> scopeIds = new Set<Id>();
        for(Product2 p : scope) {
            scopeIds.add(p.Id);
        }
        
        ActualizarPrecioProductoController appc = new ActualizarPrecioProductoController(scopeIds);
        appc.updatePrice();
    }

    public void finish(Database.BatchableContext BC) {
        // Opcional: Enviar correo de notificación o registrar log
    }
}