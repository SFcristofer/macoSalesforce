global class SchedulerBatchEnvioBooking implements Schedulable {
	global void execute(SchedulableContext sc) {
        BatchEnvioBooking beb = new BatchEnvioBooking(BatchEnvioBooking.TYPE_BATCH_SETENVIO);
        Database.executeBatch(beb);

        BatchEnvioBooking bebt = new BatchEnvioBooking(BatchEnvioBooking.TYPE_BATCH_TASK);
        Database.executeBatch(bebt);
	}
}