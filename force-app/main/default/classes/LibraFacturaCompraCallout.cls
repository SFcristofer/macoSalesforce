public class LibraFacturaCompraCallout extends LibraCallout {

    // This values were defined by do-brands
    // base = base imponible = importe
    // porcentaje = % cuota = 0 %
    // cuota = cuota = base * %cuota
    private static final String BASE_IMPONIBLE = '100';
    private static final Integer PURCHASE_TAXES = 0;

    public LibraFacturaCompraCallout(String type) {
        super(type);
    }

    public override String buildPayload(Object param) {
        LibraFacturaCompraPayload objPayload;
        LibraLineaFacturaCompraPayload lineaCompraPayload;
        LibraImpuestoFacturaCompraPayload impuestoCompraPayload;

        PedidoDeCompra__c pedido;
        String payload;
        String centroContable;
        PedidoParentAccount ped;
        String codigoImpuesto;

        Double totalCuota = 0;
        Double totalBase = 0;        

        if(param != null) {
            ped = (PedidoParentAccount)param;
            System.debug('pedname [' + ped.pedido.Name + '] [' + ped.parentAccount.Sociedad__c + ']');
            pedido = ped.pedido;

            if(ped.parentAccount.Sociedad__c != null && ped.parentAccount.Sociedad__c.equals('Do América')) {
                centroContable = '400';
                //codigoImpuesto = '20';
                codigoImpuesto = '50';                
            }
            if(ped.parentAccount.Sociedad__c != null && ped.parentAccount.Sociedad__c.equals('Do Core')) {
                centroContable = '200';
                codigoImpuesto = '50'; 
            }
            
            if(centroContable == null) {
                centroContable = '';
            }

            objPayload = new LibraFacturaCompraPayload();
            System.debug('centroContable [' + centroContable + '] [' + ped.parentAccount.Codigo_rapido__c + ']');
            objPayload.centro_contable = centroContable;

            if(objPayload.centro_contable.equals('400')) {
                //objPayload.estado = 'PAN';
                objPayload.estado = 'ESP';
                objPayload.codigo_almacen = '04';
                objPayload.organizacion_compras = '04';
                objPayload.organizacion_comercial = '04';
            }
            
            if(objPayload.centro_contable.equals('200')) {
                objPayload.estado = 'ESP';
                objPayload.codigo_almacen = '01';
                objPayload.organizacion_compras = '01';
                objPayload.organizacion_comercial = '01';
            }

            objPayload.codigo_proveedor = ped.pedido.Proveedor__r.Codigo_rapido__c;//'PR45';
            objPayload.divisa = pedido.CurrencyIsoCode; //'USD';
            objPayload.fecha_factura = pedido.Fecha_Factura_Proveedor__c.format(); //'31/07/2019';
            objPayload.fecha_cambio = pedido.Fecha_Factura_Proveedor__c.format();  //(?) //'31/07/2019';

            if(ped.exchangeRateProveedor.equals('-1')) {
                throw new DoBrandsException('No exchange rate found. Order [' + ped.pedido.Name + '] Date invoice supplier [' + objPayload.fecha_factura + ']');
            } 

            objPayload.valor_cambio = ped.exchangeRateProveedor;

            objPayload.numero_serie = 'FCO'; //(?)
            objPayload.numero_pedido = pedido.Name; //'9876';
            objPayload.numero_factura = pedido.Numero_de_Factura_Proveedor__c;//'3';
            objPayload.ejercicio = String.valueOf(pedido.Fecha_Factura_Proveedor__c.year());

            for(PedidoLineItem__c pli : pedido.PedidoLineItems__r) {
                lineaCompraPayload = new LibraLineaFacturaCompraPayload();
                lineaCompraPayload.codigo_articulo = pli.CodigoProducto__c; //'0000';
                lineaCompraPayload.cantidad = String.valueOf(pli.Unidades__c);//'5';
                lineaCompraPayload.importe = String.valueOf(pli.CostoOrigenTot__c);
                
                lineaCompraPayload.precio = String.valueOf(pli.CostoOrigen__c); //'15.5';
                objPayload.lineas.add(lineaCompraPayload);

            }
            totalBase = pedido.CostoOrigen__c / (1 + (PURCHASE_TAXES/100));
            totalCuota = totalBase * (PURCHASE_TAXES/100);
            impuestoCompraPayload = new LibraImpuestoFacturaCompraPayload();
            impuestoCompraPayload.impuesto = codigoImpuesto;
            impuestoCompraPayload.base = String.valueOf(totalBase);
            impuestoCompraPayload.porcentaje = String.valueOf(PURCHASE_TAXES);
            impuestoCompraPayload.cuota = String.valueOf(totalCuota);
            objPayload.impuestos.add(impuestoCompraPayload);

        }

        payload = JSON.serialize(objPayload);
        System.debug('PYLD [' + payload + ']');

        return payload;
    }

    public override Object processResponse(String response) {
        System.debug('Response [' + response + ']');
        return null;
    }

    public override String buildEndpoint()
    {
        String endpoint;
        endpoint = CS_ENDPOINT + '?' + PARAM_USER + '=' + CS_USER + '&' + PARAM_PWD + '=' + CS_PASS + '&' + PARAM_ALIAS + '=' + CS_ALIAS;
        return endpoint;
    }   

}