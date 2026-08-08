public class LibraPagosCallout extends LibraCallout {

	private static final String DO_CORE_NUM = '200';
	private static final String DO_AMERICA_NUM = '400';	

    private Libra_Cobros_Pagos__c libraCPCS;
	private List<PedidoDeCompra__c> pedidos;

	private String sociedad;	

	public LibraPagosCallout(String type, String psociedad) {
        super(type);
		if(psociedad.equals(DO_CORE_NUM)) {
		    libraCPCS = Util.getCSLibraFechaCobrosPagos('PagosDoCore');
			sociedad = DO_CORE_NUM;
		}
		if(psociedad.equals(DO_AMERICA_NUM)) {
		    libraCPCS = Util.getCSLibraFechaCobrosPagos('PagosDoAmerica');
			sociedad = DO_AMERICA_NUM;
		}
	}

	public override String buildPayload(Object param) {
		pedidos = (List<PedidoDeCompra__c>)param;
        String payload;
		Datetime lastSuccessDate;
		Datetime datetImeNow;

		LibraPagosPayload objPayload = new LibraPagosPayload();

        if(libraCPCS != null) {
           lastSuccessDate = libraCPCS.Fecha_Callout_Exitosa__c;
		   datetImeNow = Datetime.now();
		}

        String strDateIni = lastSuccessDate.format('dd/MM/yyyy');
        String strDateFin = datetImeNow.format('dd/MM/yyyy');

        System.debug(' dateIni[' + strDateIni + '] dateFin[' + strDateFin + ']');

	    objPayload.codigo_empresa = sociedad;
	    objPayload.fecha_desde = strDateIni; 
	    objPayload.fecha_hasta = strDateFin;
        payload = JSON.serialize(objPayload);

		return payload;
	}

	public override Object processResponse(String response) {
		Account proveedor;
        Map<String, Account> codigoProveedorMap;
		Date fechaPago;
        PedidoDeCompra__c pc;
        LibraPagosResult resultPagos;
		List<Pago__c> pagosLibra = new List<Pago__c>();
		Pago__c pago;
		List<String> codigosProveedor = new List<String>();

		if(response != null) {
		    resultPagos = (LibraPagosResult)JSON.deserialize(response, LibraPagosResult.class);
		}		

        if(resultPagos != null) {

            System.debug('TAMANO: ' + resultPagos.pagos.size() );
            for(LibraPagoResult pagoL : resultPagos.pagos) {
	            fechaPago = Util.convertDateStrToSF(pagoL.fecha_pago);

	            pago = new Pago__c(Codigo_de_empresa__c = sociedad,//pagoL.codigo_empresa,
		                           Fecha_Pago__c = fechaPago,
		                           Ejercicio__c = Integer.valueOf(pagoL.ejercicio),
							       codigo_proveedor__c = pagoL.codigo_proveedor,
							       nombre_proveedor__c = pagoL.nombre_proveedor,
						           Importe_Pagado__c = Decimal.valueOf(pagoL.importe_pagado),
						           Numero_Factura__c = pagoL.numero_factura);

                codigosProveedor.add(pagoL.codigo_proveedor);
                pc = findPedidoSF(pedidos, sociedad, pagoL.numero_factura);
			    if(pc != null) {
			       pago.Pedido__c = pc.Id;
			    }
                pagosLibra.add(pago);
                System.debug(sociedad + ',' + pagoL.numero_factura + ',' + pagoL.ejercicio + ',' + pagoL.importe_pagado + ',' + pagoL.fecha_pago);
		    }
		}

        codigoProveedorMap = getMapProveedores(codigosProveedor);

		for(Pago__c pagoLibra : pagosLibra) {
            proveedor = codigoProveedorMap.get(pagoLibra.codigo_proveedor__c);
			if(proveedor != null) {
			    pagoLibra.Proveedor__c = proveedor.Id;
			}
		}

		insert pagosLibra;
        updateCS();

		if(resultPagos != null) {
		    System.debug('pedidos.size[' + pedidos.size() + '] pagosLibra[' + resultPagos.pagos.size() + ']');
		}
		return null;
	}

	public override String buildEndpoint() {
		String endpoint;
		endpoint = CS_ENDPOINT + '?' + PARAM_USER + '=' + CS_USER + '&' + PARAM_PWD + '=' + CS_PASS + '&' + PARAM_ALIAS + '=' + CS_ALIAS;
		return endpoint;
	}

	private void updateCS() {
        libraCPCS.Fecha_Callout_Exitosa__c = Datetime.now();
		update libraCPCS;
	}

    private PedidoDeCompra__c findPedidoSF(List<PedidoDeCompra__c> pedidos, String pcodigoEmpresaLibra, String pnumeroFacturaLibra) {
		String sociedadSF;
        String numSociedad;
		PedidoDeCompra__c result;

		for(PedidoDeCompra__c pc : pedidos) {
			sociedadSF = pc.Proforma__r.Cuenta__r.Parent.Sociedad__c;

            if(sociedadSF.equals('Do Core')) {
                numSociedad = '200';
            } else {
                numSociedad = '400';
            }

			if(numSociedad.equals(pcodigoEmpresaLibra) && pc.Numero_de_Factura_Proveedor__c.equals(pnumeroFacturaLibra)) {
                result = pc;
				break;
			}
		}
		return result;
	}

	private Map<String, Account> getMapProveedores(List<String> codigosProveedor) {
		RecordType rt;
		Map<String, Account> mapCodigoProveedor = new Map<String, Account>();
		List<Account> proveedores;
		rt = DOBrandsDAO.getRecordType('Proveedor', 'Account');
        proveedores = DOBrandsDAO.getAccountByCodigoRapido(codigosProveedor, rt);
		for(Account prov : proveedores) {
            mapCodigoProveedor.put(prov.Codigo_rapido__c, prov);
		}
		return mapCodigoProveedor;
	}
}