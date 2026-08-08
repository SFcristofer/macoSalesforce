global class QBBillSchedulerQueryBatch implements Schedulable {

    global void execute(SchedulableContext sc) {
        QBBillQueryBatch batch = new QBBillQueryBatch();
        Database.executeBatch(batch, 10);
    }

}