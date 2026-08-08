global class QBBillSchedulerBatch implements Schedulable {

    global void execute(SchedulableContext sc) {
        QBBillBatch qbBillBatch = new QBBillBatch();
        Database.executeBatch(qbBillBatch, 10);
    }

}