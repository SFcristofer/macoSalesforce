global class QBJournalEntrySchedulerBatch implements Schedulable {

    global void execute(SchedulableContext sc) {
        QBJournalEntryBatch qbJournalEntryBatch = new QBJournalEntryBatch();
        Database.executeBatch(qbJournalEntryBatch, 10);
    }

}