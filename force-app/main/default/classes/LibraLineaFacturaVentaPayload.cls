public class LibraLineaFacturaVentaPayload 
{
	public String codigo_articulo {get; set;}
	public String cantidad {get; set;}
	public String importe {get; set;}
	public String precio {get; set;}

	public String valor_cambio_coste {get; set;}
	public String importe_coste {get; set;}

	public LibraLineaFacturaVentaPayload() 
	{
	}
}