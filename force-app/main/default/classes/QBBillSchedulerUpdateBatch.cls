global class QBBillSchedulerUpdateBatch implements Schedulable {

    global void execute(SchedulableContext sc) {
        QBBillUpdateBatch batch = new QBBillUpdateBatch();
        Database.executeBatch(batch, 10);
    }

}