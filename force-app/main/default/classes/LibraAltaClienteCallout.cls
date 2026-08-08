public class LibraAltaClienteCallout extends LibraCallout
{
	public LibraAltaClienteCallout(String type) {
	    super(type);
	}

	public override String buildPayload(Object param) {
        String payload;
		LibraAltaClientePayload objPayload = new LibraAltaClientePayload();

		AccountBatchLibra clienteToSend = (AccountBatchLibra)param;

	    objPayload.tipo_cambio = 'I';
	    objPayload.codigo_empresa = clienteToSend.identifierSociedad;
	    objPayload.codigo_rapido = clienteToSend.account.Codigo_rapido__c;
	    objPayload.nif = clienteToSend.account.NroIdFiscal__c;
	    objPayload.nombre = clienteToSend.account.Name;
	    objPayload.razon_social = clienteToSend.account.RazonSocial__c;
	    objPayload.estado = clienteToSend.account.Codigo_pais2__c;
	    objPayload.forma_cobro_pago = 'CON';

	    objPayload.direccion = clienteToSend.account.BillingStreet;
	    objPayload.localidad = clienteToSend.account.BillingCity;
	    objPayload.codigo_postal = clienteToSend.account.BillingPostalCode;
	    objPayload.provincia = clienteToSend.account.Codigo_pais2__c;
	    objPayload.divisa = clienteToSend.account.CurrencyIsoCode;

        payload = JSON.serialize(objPayload);

		return payload;
	}

	public override Object processResponse(String response) {
        LibraStatusResponse resultAltaCliente;
		System.debug('CALL RESULT[' + response + ']');
		String result = '';

		return result;
	}

	public override String buildEndpoint() {
		String endpoint;
		endpoint = CS_ENDPOINT + '?' + PARAM_USER + '=' + CS_USER + '&' + PARAM_PWD + '=' + CS_PASS + '&' + PARAM_ALIAS + '=' + CS_ALIAS;
		return endpoint;
	}
}