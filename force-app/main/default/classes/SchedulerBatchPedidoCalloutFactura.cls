global class SchedulerBatchPedidoCalloutFactura implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        BatchPedidoCalloutFactura bpcfl = new BatchPedidoCalloutFactura();
        Database.executeBatch(bpcfl, 10);       
    }

}