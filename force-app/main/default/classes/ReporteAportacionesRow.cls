public class ReporteAportacionesRow 
{
	public Account parentAccount {set; get;}
	public Aportacion__c aportacion {set; get;}
	public String idAportacion {set; get;}
	public String compradorName {set; get;}
	public String idTopParent {set; get;}
	public String sociedad {set; get;}	

	public ReporteAportacionesRow(String pidAportacion, Aportacion__c paportacion) 
	{
       idAportacion = pidAportacion;
	   aportacion = paportacion;
	   setCompradorName();
	}

    public void addParentAccount(Account pparentAccount)
	{
      parentAccount = pparentAccount;
	}

	private void setCompradorName()
	{
		String[] tokens;
		if(aportacion.Planificacioncomercial__r.Cuenta__r.Name != null)
		{
           tokens = aportacion.Planificacioncomercial__r.Cuenta__r.Name.split('-');
		   if(tokens.size() > 1)
		   {
			   compradorName = tokens[1];
		   }
		   else 
		   {
			   compradorName = tokens[0];
		   }
		}
	}
}