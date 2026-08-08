global class SchedulerBatchCobrosLibra implements Schedulable 
{

	global void execute(SchedulableContext sc) 
	{
        BatchCobrosLibra bcl = new BatchCobrosLibra();
        Database.executeBatch(bcl);		
	}
}