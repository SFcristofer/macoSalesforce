global class QBInvoiceSchedulerBatch implements Schedulable {

    global void execute(SchedulableContext sc) {
        QBInvoiceBatch qbInvoiceBatch = new QBInvoiceBatch();
        Database.executeBatch(qbInvoiceBatch, 10);
    }

}