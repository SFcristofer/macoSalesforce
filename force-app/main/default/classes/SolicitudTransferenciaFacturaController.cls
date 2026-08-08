public class SolicitudTransferenciaFacturaController 
{
    public List<SelectOption> aprobaciones {get;set;}
    public String selectedAprobacion {get;set;}	

	public SolicitudTransferenciaFacturaController() 
	{
		aprobaciones = new List<SelectOption>();
		initAprobaciones();
	}

     public void initAprobaciones()
	 {
		 System.debug('inoit aporbaciones');
         SelectOption transferencia = new SelectOption('Transferencias', 'Transferencias');
         SelectOption factura = new SelectOption('Facturas', 'Facturas');
		 aprobaciones.add(transferencia);
		 aprobaciones.add(factura);	
		 System.debug('inoit aporbaciones [' + aprobaciones.size() + ']');		 	 
	 }

	 public PageReference  siguiente() 
	 {
		 PageReference pr;
		 System.debug('selectedAprobacion [' + selectedAprobacion + ']');
		 if(selectedAprobacion.equals('Facturas'))
		 {
		     pr = new PageReference('/apex/FacturasLibraAprobacion');
		 }
		 if(selectedAprobacion.equals('Transferencias'))
		 {
		     pr = new PageReference('/apex/SolicitudTransferenciaAprobacion');
		 }
         pr.setRedirect(true);
         return pr;
	 }
}