/**
*   Backup dev2
*/
public class SolicitudTransferenciaController 
{
    private String ESTATUS_PEDIDO_CONFIRMADO = 'PEDIDO CONFIRMADO';//confirmo el cliente
    private String ESTATUS_PEDIDO_PACKAGING = 'PACKAGING';//Confirmo el proveedor
    private String TIPODOC_CONFIRMACION = 'Confirmación Proveedor';
    private String TIPODOC_FACTURA = 'Factura';
    private String TIPOPROC_PEDIDO_FABRICA = 'Pedido Fábrica';
    private String PEDIDO_INFO_SIN_DEPOSITO = 'Sin depósito';
	private static String EMAIL_SUBJECT = 'Resumen Aprobación Transferencias';
    
	public List<PedidoDeCompra__c> pedidos {set; get;}
	public Boolean checkTest {set; get;}
    public List<PedidoTransferencia> pedidosTransferencia {set; get;}
    private List<String> documentoTipo;
    public String selectedAprobacion {get;set;}
    
    List<PedidoDeCompra__c> pedidosAprobados;
    public List<PedidoTransferencia> pedidosSeleccionados {set; get;}
	private List<String> emailNotificationList;
    private String currentBaseURL;

	public SolicitudTransferenciaController() {
		List<Envio_Correos__c> csEnvioCorreosList;
        documentoTipo = new List<String>();
        documentoTipo.add(TIPODOC_CONFIRMACION);
        documentoTipo.add(TIPODOC_FACTURA);

		emailNotificationList = new List<String>();
		currentBaseURL = URL.getSalesforceBaseUrl().toExternalForm();

        csEnvioCorreosList = Util.getCSCorreosTransferencia('aprobacionFacturas');
		for(Envio_Correos__c cs : csEnvioCorreosList) {
			emailNotificationList.add(cs.correo_electronico__c);
		}
        loadPedidosDeposito();
        loadPedidosBalance();
        sortUpdatePedidos();
		selectedAprobacion = 'Transferencias';
	}

    public void loadPedidosDeposito() {
        PedidoTransferencia pedidoTr;
        List<PedidoDeCompra__c> pedidos;

        pedidos = [SELECT Id, 	
		                  Name,
                          RecordTypeId,
                          FechaConfirmacionCliente__c,
                          Fecha_Plazo_Remanete__c, //ETD__c + Proveedor__r.Plazo_pago_int__c
                          Fecha_de_Carga_de_Contenedor__c,
                          PorcentajeDepositoAFabrica__c,
                          Cuenta__c,
                          RefOpp__c,
                          Proveedor__c,
                          Estado2__c,
                          CostoOrigen__c,
                          ImporteAdelantado__c,
                          ETD__c, 
                          Proveedor__r.Name,
                          Proveedor__r.PlazoPago__c,
                          Proveedor__r.Plazo_Pago_int__c,
                          Proveedor__r.TitularCuenta__c,
                          Proforma__r.Cuenta__r.Parent.Sociedad__c,
                          Correo_Pago_Deposito__c,
                          correo_pago_balance__c,
                          Aprobada_Transferencia_Balance__c,
                          Aprobada_Transferencia_Deposito__c,
                          Monto_deposito__c, 
                          Numero_de_Factura_Proveedor__c,
                          (SELECT Id, 
						          Name,
                                  Proceso__c,
                                  Tipo_de_Documento__c
						     FROM Documentos__r 
						    WHERE Proceso__c = :TIPOPROC_PEDIDO_FABRICA
                            AND Tipo_de_Documento__c IN :documentoTipo)
                     FROM PedidoDeCompra__c
                    WHERE (FechaConfirmacionCliente__c != null AND FechaConfirmacionCliente__c <= :Date.today())
                      AND Correo_Pago_Deposito__c = false // no se ha enviado el correo de solicitud de transferencia de deposito
                      AND Aprobada_Transferencia_Deposito__c = false
                      AND (PorcentajeDepositoAFabrica__c != null AND PorcentajeDepositoAFabrica__c != 0)
                      AND RecordType.DeveloperName = 'Principal'];

        pedidosTransferencia = new List<PedidoTransferencia>();
        for(PedidoDeCompra__c p : pedidos) {
           if(p.Documentos__r.isEmpty()) {
               continue;
           }
           pedidoTr = new PedidoTransferencia();
           pedidoTr.pedido = p;
           pedidoTr.urlOrder = currentBaseURL + '/' + p.Id;
           pedidoTr.importe = calcularMontoDeposito(p);
           pedidoTr.tipo = 'Depósito';
           pedidoTr.informacion = p.PorcentajeDepositoAFabrica__c + '% del importe total';
           pedidosTransferencia.add(pedidoTr);
        }
    }

    public void loadPedidosBalance() {
        PedidoTransferencia pedidoTr;
        List<PedidoDeCompra__c> pedidos;

        pedidos = [SELECT Id, 	
		                  Name,
                          FechaConfirmacionCliente__c,
                          Fecha_Plazo_Remanete__c, //ETD__c + Proveedor__r.Plazo_pago_int__c
                          Fecha_de_Carga_de_Contenedor__c,
                          PorcentajeDepositoAFabrica__c,
                          Cuenta__c,
                          RefOpp__c,
                          Proveedor__c,
                          Estado2__c,
                          CostoOrigen__c,
                          ImporteAdelantado__c,
                          ETD__c, //ETD__c 
                          Proveedor__r.Name,
                          Proveedor__r.PlazoPago__c,
                          Proveedor__r.Plazo_Pago_int__c,
                          Proveedor__r.TitularCuenta__c,
                          Proforma__r.Cuenta__r.Parent.Sociedad__c,                          
                          Correo_Pago_Deposito__c,
                          correo_pago_balance__c,
                          Aprobada_Transferencia_Balance__c,
                          Aprobada_Transferencia_Deposito__c,
                          Monto_deposito__c,
                          Numero_de_Factura_Proveedor__c,
                          (SELECT Id, 
						          Name,
                                  Proceso__c,
                                  Tipo_de_Documento__c
						     FROM Documentos__r 
						    WHERE Proceso__c = :TIPOPROC_PEDIDO_FABRICA
                            AND Tipo_de_Documento__c IN :documentoTipo)
                     FROM PedidoDeCompra__c
                    WHERE (Fecha_Plazo_Remanete__c != null AND Fecha_Plazo_Remanete__c <= :Date.today())
                      AND (Correo_Pago_Deposito__c = true OR PorcentajeDepositoAFabrica__c = 0)// no se ha enviado el correo de solicitud de transferencia de deposito
                      AND Correo_pago_balance__c = false
                      AND Aprobada_Transferencia_Balance__c = false
                      AND RecordType.DeveloperName = 'Principal'];

        for(PedidoDeCompra__c p : pedidos) {
            if(p.Documentos__r == null) {
               continue;
           }
           pedidoTr = new PedidoTransferencia();
           pedidoTr.pedido = p;
           pedidoTr.urlOrder = currentBaseURL + '/' + p.Id;
           pedidoTr.importe = calcularBalance(p);
           pedidoTr.tipo = 'Balance';
           if(p.PorcentajeDepositoAFabrica__c == 0) {
               pedidoTr.informacion = PEDIDO_INFO_SIN_DEPOSITO;
           } else {
               pedidoTr.informacion = 'Se envió previamente la solicitud de pago de depósito por $' + String.valueOf(p.Monto_deposito__c);
           }
           pedidosTransferencia.add(pedidoTr);
        }
    }

    private void sortUpdatePedidos() {
        Integer counter = 1;        
        pedidosTransferencia.sort();
        for(PedidoTransferencia pt : pedidosTransferencia) {
            pt.consecutivo = counter;
            counter ++;            
        }
    }


	public PageReference aprobar() {
       PageReference pr;

       update pedidosAprobados;
	   buildAndSendMessage(emailNotificationList, EMAIL_SUBJECT);       
       loadPedidosDeposito();
       loadPedidosBalance();
       sortUpdatePedidos();
       
	   pr = new PageReference('/apex/SolicitudTransferenciaAprobacion');
	   pr.setRedirect(true);
	   return pr;
	}


	public PageReference selectTransfers() {
		PageReference pr;

		pedidosSeleccionados = new List<PedidoTransferencia>();        
        pedidosAprobados = new List<PedidoDeCompra__c>();
        for(PedidoTransferencia pt : pedidosTransferencia) {
            if(pt.selected) {
                if(pt.tipo.equals('Depósito')) {
                    pt.pedido.Aprobada_Transferencia_Deposito__c = true;
                    pt.pedido.Fecha_Aprobacion_Pago_Deposito__c = Date.today();
                    pt.pedido.Monto_deposito__c = pt.importe;                    
                }
                if(pt.tipo.equals('Balance')) {
                    pt.pedido.Aprobada_Transferencia_Balance__c = true;
                    pt.pedido.Fecha_Aprobacion_Pago_Balance__c = Date.today();
                }
                pedidosAprobados.add(pt.pedido);
                pedidosSeleccionados.add(pt);
            }
        }

		pr = new PageReference('/apex/SolicitudTransferenciaAprobacionResumen');
		return pr;
     }
 

     public PageReference regresar() {
		PageReference pr;
        pr = new PageReference('/apex/SolicitudTransferenciaAprobacion');
		return pr;
	}


    public Decimal calcularMontoDeposito(PedidoDeCompra__c pedidoC) {
        if(pedidoC.Monto_Deposito__c != null) {
            return pedidoC.Monto_Deposito__c;
        } else {
            Decimal resultado = 0;
            Decimal porcentaje = 0;
            Decimal costo;
            if(pedidoC.CostoOrigen__c != null) {
            costo = pedidoC.CostoOrigen__c;//Costo Fabrica (total)
            }
            if(pedidoC.PorcentajeDepositoAFabrica__c != null) {
                porcentaje = pedidoC.PorcentajeDepositoAFabrica__c;
            }
            resultado = (porcentaje/100) * costo;
            return resultado;
        }
    }

    public Decimal calcularBalance(PedidoDeCompra__c pedidoC) {
        Decimal resultado = 0;
        Decimal costo = 0;
        Decimal deposito = 0;
        if(pedidoC.CostoOrigen__c != null) {
           costo = pedidoC.CostoOrigen__c;
        }
        if(pedidoC.Monto_deposito__c != null) {
           deposito = pedidoC.Monto_deposito__c;
        }
        resultado = costo - deposito;
        return resultado;
    }

	public PageReference changePage() {
		PageReference pr;
        pr = new PageReference('/apex/FacturasLibraAprobacion');
		pr.setRedirect(true);
		return pr;
	}


	private static void buildAndSendMessage(List<String> deliveryMail, String subject) {
        String pageAsString;
        PageReference pr = Page.SolicitudTransferAprobacionEmailTemplate;
        if(Test.isRunningTest()) {
            pageAsString = 'tst';
        } else {
            pageAsString = pr.getContent().tostring();
        }

		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		message.toAddresses = deliveryMail;
		message.subject = subject;
        message.htmlBody = pageAsString;		
		Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
  
		Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
	 }

}