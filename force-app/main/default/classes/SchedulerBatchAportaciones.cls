global class SchedulerBatchAportaciones implements Schedulable 
{
	global void execute(SchedulableContext sc) 
	{
        BatchAportaciones ba = new BatchAportaciones();
        Database.executeBatch(ba);		
	}
}