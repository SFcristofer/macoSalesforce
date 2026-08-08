global class QBInvoiceSchedulerQueryBatch implements Schedulable {

    global void execute(SchedulableContext sc) {
        QBInvoiceQueryBatch batch = new QBInvoiceQueryBatch();
        Database.executeBatch(batch, 10);
    }

}