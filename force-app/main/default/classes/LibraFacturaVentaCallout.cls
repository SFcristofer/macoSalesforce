public class LibraFacturaVentaCallout extends LibraCallout {
    
    // This values were defined by do-brands
    // base = base imponible = 100
    // porcentaje = % cuota = 0 %
    // cuota = cuota = 0
    private static final String BASE_IMPONIBLE = '100';
    private static final Integer SALES_TAXES = 0;

    private static final String SKIP_PRODUCT_CODE = '22222222';    
    
    public LibraFacturaVentaCallout(String type) {
        super(type);
    }

    public override String buildPayload(Object param) {
        LibraFacturaVentaPayload objPayload;
        LibraLineaFacturaVentaPayload lineaCompraPayload;
        LibraImpuestoFacturaVentaPayload impuestoVentaPayload;

        String payload;
        String idPedido;
        PedidoDeCompra__c pedido;
        String centroContable;
        String codigoImpuesto;
        PedidoParentAccount ped;
        String serieFactura;

        Double totalCuota = 0;
        Double totalCosto = 0;
        Double importe = 0;
        
        if(param != null) {
            ped = (PedidoParentAccount)param;
            System.debug('pedname [' + ped.pedido.Name + ']');
            pedido = ped.pedido;

            if(ped.parentAccount.Sociedad__c != null && ped.parentAccount.Sociedad__c.equals('Do América')) {
                centroContable = '400';
                //codigoImpuesto = '00';
                codigoImpuesto = '12';                
                serieFactura = ped.prefixInvoiceDoAmerica;
            }

            if(ped.parentAccount.Sociedad__c != null && ped.parentAccount.Sociedad__c.equals('Do Core')) {
                centroContable = '200';
                codigoImpuesto = '12';
                serieFactura = ped.prefixInvoiceDoCore;
            }

            if(centroContable == null) {
                centroContable = '';
            }

            objPayload = new LibraFacturaVentaPayload();
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

            objPayload.codigo_cliente = ped.parentAccount.Codigo_rapido__c; 
            objPayload.divisa = pedido.Proforma__r.CurrencyIsoCode;
            if(ped.isCancel) {
                objPayload.fecha_factura = pedido.Fecha_Cancelacion_Factura__c.format();
            } else {
                objPayload.fecha_factura = pedido.Fecha_Factura__c.format();
            }
            
            objPayload.fecha_cambio = pedido.Fecha_Factura__c.format();
            if(ped.exchangeRateCliente.equals('-1')) {
                throw new DoBrandsException('No exchange rate found. Order [' + ped.pedido.Name + '] Date invoice customer [' + objPayload.fecha_factura + ']');
            } 
            objPayload.valor_cambio = ped.exchangeRateCliente;

            objPayload.numero_pedido =  pedido.Name;
            objPayload.numero_factura = getNumeroFacturaLibra(pedido.Numero_de_Factura__c);
            objPayload.ejercicio = String.valueOf(pedido.Fecha_Factura__c.year());
            objPayload.numero_serie = serieFactura + objPayload.ejercicio.substring(2,4);

            for(PedidoLineItem__c pli : pedido.PedidoLineItems__r) {
                
                //Products (costo extra) with 2222222 code will not be added ti line items list
                if(pli.CodigoProducto__c.equals(SKIP_PRODUCT_CODE)) {
                    continue;
                }

                lineaCompraPayload = new LibraLineaFacturaVentaPayload();
                lineaCompraPayload.codigo_articulo = pli.CodigoProducto__c;
                if(ped.isCancel) {
                    lineaCompraPayload.cantidad = String.valueOf(pli.UnidadesPorMasterbox__c * pli.NumeroDeCajas__c * (-1));
                } else {
                    lineaCompraPayload.cantidad = String.valueOf(pli.UnidadesPorMasterbox__c * pli.NumeroDeCajas__c);
                }
                
                if(ped.isCancel) {
                    importe = pli.PrecioDeVentaTot__c * -1;
                } else {
                    importe = pli.PrecioDeVentaTot__c;
                }

                lineaCompraPayload.importe = String.valueOf(importe);
                lineaCompraPayload.precio = String.valueOf(pli.PrecioDeVenta__c);
                lineaCompraPayload.valor_cambio_coste = objPayload.valor_cambio;
                lineaCompraPayload.importe_coste = String.valueOf(pli.CostoOrigen__c * pli.Unidades__c) ;                

                objPayload.lineas.add(lineaCompraPayload);

            }

            if(ped.isCancel) {
                totalCosto = pedido.Precio_Total__c * -1;
            } else {
                totalCosto = pedido.Precio_Total__c;
            }

            totalCuota = totalCosto * (SALES_TAXES/100);
            impuestoVentaPayload = new LibraImpuestoFacturaVentaPayload();
            impuestoVentaPayload.impuesto = codigoImpuesto;
            impuestoVentaPayload.base = String.valueOf(totalCosto);
            impuestoVentaPayload.porcentaje = String.valueOf(SALES_TAXES);
            impuestoVentaPayload.cuota = String.valueOf(totalCuota);
            objPayload.impuestos.add(impuestoVentaPayload);

        }

        payload = JSON.serialize(objPayload);
        System.debug('PLD [' + payload + ']');

        return payload;
    }

     
    private String getNumeroFacturaLibra(String numeroFactura) {
        String numero = '';
        String[] tokens;
        tokens = numeroFactura.split('/');
        if(tokens.size() == 2) {
            numero = tokens[1];
            System.debug('numFactL [' + numero + ']');
        }
        return numero;
    }

    public override Object processResponse(String response) {
        System.debug('Response [' + response + ']');
        return null;
    }
    
    public override String buildEndpoint() {
        String endpoint;
        endpoint = CS_ENDPOINT + '?' + PARAM_USER + '=' + CS_USER + '&' + PARAM_PWD + '=' + CS_PASS + '&' + PARAM_ALIAS + '=' + CS_ALIAS;
        return endpoint;
    }   

}