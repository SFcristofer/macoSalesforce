@isTest
private class TestSolicitudTransferenciaFacturaCtrl 
{
	
	@isTest static void testSolicitudTransferenciaFacturaCtrl() 
	{
       SolicitudTransferenciaFacturaController tstc = new SolicitudTransferenciaFacturaController();
	   tstc.selectedAprobacion = 'Facturas';
	   tstc.siguiente();
	   tstc.selectedAprobacion = 'Transferencias';
	   tstc.siguiente();
	}
	
}