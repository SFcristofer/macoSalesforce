public class AportacionTriggerHelper 
{
    public static final String INS = 'ins';
    public static final String DEL = 'del';
    public static final String UPD = 'upd';    
    private String oper;

    private List<Aportacion__c> aportaciones;	

	public AportacionTriggerHelper(List<Aportacion__c> pAportaciones, String pOper) 
	{
        aportaciones = pAportaciones;
        oper = pOper;
        System.debug('aportaciones[' + pAportaciones.size() + ']');
	}

    public void execute()
	{
        if(this.oper == INS)
        {
            System.debug('aportacion trigger helper INS');
            for(Aportacion__c aportacion : aportaciones)
            {
               aportacion.Name = Util.getIncrement('aportacion');          
			}
		}
	}
}