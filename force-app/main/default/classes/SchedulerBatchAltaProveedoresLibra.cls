global  class SchedulerBatchAltaProveedoresLibra implements Schedulable {
    global void execute(SchedulableContext sc) {
        BatchAltaProveedoresLibra bapl = new BatchAltaProveedoresLibra();
        Database.executeBatch(bapl, 10);        
    }
}