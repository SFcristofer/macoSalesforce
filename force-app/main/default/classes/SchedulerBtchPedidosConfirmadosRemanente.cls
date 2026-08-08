global class SchedulerBtchPedidosConfirmadosRemanente implements Schedulable {

    global void execute(SchedulableContext sc) {
        BatchPedidosConfirmados bpc = new BatchPedidosConfirmados('REMANENTE');
        Database.executeBatch(bpc, 10);        
    }

}