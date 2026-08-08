public class LibraAltaProveedorCallout extends LibraCallout
{
    public LibraAltaProveedorCallout(String type) 
    {
        super(type);
    }

    public override String buildPayload(Object param) {
        String payload;
        LibraAltaProveedorPayload objPayload = new LibraAltaProveedorPayload();

        AccountBatchLibra proveedorToSend = (AccountBatchLibra)param;

        objPayload.tipo_cambio = 'I';
        objPayload.codigo_empresa = proveedorToSend.identifierSociedad;
        objPayload.codigo_rapido = proveedorToSend.codigoRapido;
        objPayload.nif = proveedorToSend.account.NroIdFiscal__c;//'0T';
        objPayload.nombre = proveedorToSend.account.Name;//'Fujian';
        objPayload.razon_social = proveedorToSend.account.RazonSocial__c;//'razon social tets';
        objPayload.estado = proveedorToSend.account.Codigo_pais2__c;
        objPayload.forma_pago = 'CON';
        objPayload.divisa = proveedorToSend.account.CurrencyIsoCode;
         objPayload.direccion = proveedorToSend.account.BillingStreet;
        objPayload.localidad = proveedorToSend.account.BillingCity == null ? 'LOC' : proveedorToSend.account.BillingCity;
        objPayload.codigo_postal = proveedorToSend.account.BillingPostalCode;
        objPayload.provincia = proveedorToSend.account.Codigo_pais2__c;
        objPayload.acreedor = 'N';

        payload = JSON.serialize(objPayload);

        return payload;
    }

    public override Object processResponse(String response) {
        System.debug('CALL RESULT[' + response + ']');
        return null;
    }

    public override String buildEndpoint()
    {
        String endpoint;
        endpoint = CS_ENDPOINT + '?' + PARAM_USER + '=' + CS_USER + '&' + PARAM_PWD + '=' + CS_PASS + '&' + PARAM_ALIAS + '=' + CS_ALIAS;
        return endpoint;
    }
}