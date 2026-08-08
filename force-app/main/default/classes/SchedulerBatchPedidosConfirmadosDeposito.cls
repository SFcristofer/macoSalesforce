global class SchedulerBatchPedidosConfirmadosDeposito implements Schedulable {

    global void execute(SchedulableContext sc) {
        BatchPedidosConfirmados bpc = new BatchPedidosConfirmados('DEPOSITO');
        Database.executeBatch(bpc, 10);        
    }

}