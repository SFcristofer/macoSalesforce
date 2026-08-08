public class LibraFacturaVentaPayload 
{
	//public String numero_secuencia {get; set;}
	public String codigo_empresa {get; set;}
	public String codigo_cliente {get; set;}
    public String estado {get; set;}	

	public String numero_serie {get; set;}
	public String numero_pedido {get; set;}	
	public String numero_factura {get; set;}

	public String divisa {get; set;}	
	public String fecha_factura {get; set;}

	public String ejercicio {get; set;}

	public String fecha_cambio {get; set;}
	public String valor_cambio {get; set;}

    public String centro_contable {get; set;}
    public String codigo_almacen {get; set;}
    public String organizacion_compras {get; set;}
    public String organizacion_comercial {get; set;}

    public List<LibraImpuestoFacturaVentaPayload> impuestos {set; get;}
    public List<LibraLineaFacturaVentaPayload> lineas {set; get;}

	public LibraFacturaVentaPayload()  {
		codigo_empresa = '200';		
	    lineas	= new List<LibraLineaFacturaVentaPayload>();
		impuestos = new List<LibraImpuestoFacturaVentaPayload>();
	}
}