global class QBBillSchedulerQuerySTokenBatch implements Schedulable {

    global void execute(SchedulableContext sc) {
        QBBillQuerySTokenBatch batch = new QBBillQuerySTokenBatch();
        Database.executeBatch(batch, 10);
    }

}