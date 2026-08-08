global class SchedulerBatchAltaClientesLibra implements Schedulable {

    global void execute(SchedulableContext sc) {
        BatchAltaClientesLibra bacl = new BatchAltaClientesLibra();
        Database.executeBatch(bacl, 10);        
    }

}