global class SchedulerBatchPagosLibra implements Schedulable 
{

	global void execute(SchedulableContext sc) 
	{
        BatchPagosLibra bpl = new BatchPagosLibra();
        Database.executeBatch(bpl);
	}
}