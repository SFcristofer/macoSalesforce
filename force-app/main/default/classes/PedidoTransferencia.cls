public class PedidoTransferencia implements Comparable
{
	public Integer consecutivo {set; get;}
	public PedidoDeCompra__c pedido {set; get;}
	public Decimal importe {set; get;}
    public String tipo {set; get;}
    public String informacion {set; get;}
	public Boolean selected {set; get;}	
    public String urlOrder {set; get;}

	public PedidoTransferencia() 
	{
		
	}

    public Integer compareTo(Object compareTo) 
	{
        PedidoTransferencia compareToPT = (PedidoTransferencia)compareTo;
        return this.pedido.Name.compareTo(compareToPT.pedido.Name);
    }

}