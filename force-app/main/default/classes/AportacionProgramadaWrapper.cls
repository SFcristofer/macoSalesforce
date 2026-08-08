public class AportacionProgramadaWrapper 
{
	public ProgramacionDeAportaciones__c aportacion {set; get;}
	public Opportunity opp {set; get;}
    public PedidoDeCompra__c order {set; get;}
	public String type {set; get;}
	public Decimal oldAmount {set; get;}	

	public AportacionProgramadaWrapper() 
	{
	}
}