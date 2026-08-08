global class SchedulerBatchProductosLibra implements Schedulable {

    global void execute(SchedulableContext sc) {
        BatchProductosLibra bpl = new BatchProductosLibra();
        Database.executeBatch(bpl, 10);     
    }

}