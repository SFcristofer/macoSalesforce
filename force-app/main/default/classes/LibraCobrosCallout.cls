public class LibraCobrosCallout extends LibraCallout
{
    private static final String DO_CORE = 'Do Core';
    private static final String DO_CORE_NUM = '200';
    private static final String DO_AMERICA_NUM = '400'; 

    private Libra_Cobros_Pagos__c libraCPCS;
    private List<PedidoDeCompra__c> pedidos;
    private List<PedidoDeCompra__c> pedidosMatched;

    private String sociedad;

    public LibraCobrosCallout(String type, String psociedad) {
        super(type);
        if(psociedad.equals(DO_CORE_NUM)) {
            libraCPCS = Util.getCSLibraFechaCobrosPagos('CobrosDoCore');
            sociedad = DO_CORE_NUM;
        }
        if(psociedad.equals(DO_AMERICA_NUM)) {
            libraCPCS = Util.getCSLibraFechaCobrosPagos('CobrosDoAmerica');
            sociedad = DO_AMERICA_NUM;
        }
        pedidosMatched = new List<PedidoDeCompra__c>();
    }

    public override String buildPayload(Object param) {
        pedidos = (List<PedidoDeCompra__c>)param;       
        String payload;
        Datetime lastSuccessDate;
        Datetime datetImeNow;
        LibraCobrosPayload objPayload = new LibraCobrosPayload();

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
        Account cliente;
        Map<String, Account> codigoClienteMap;

        Date fechaCobro;
        LibraCobrosResult resultCobros;
        
        PedidoDeCompra__c pc;
        List<Cobro__c> cobrosLibra = new List<Cobro__c>();
        Cobro__c cobro;
        List<String> codigosCliente = new List<String>();

        System.debug('Cobros repsonse [' + response + ']');
        if(response != null) {
            resultCobros = (LibraCobrosResult)JSON.deserialize(response, LibraCobrosResult.class);
        }

        if(resultCobros != null) {
            for(LibraCobroResult cobroL : resultCobros.cobros) {
                fechaCobro = Util.convertDateStrToSF(cobroL.fecha_cobro);

                cobro = new Cobro__c(Codigo_Empresa__c = sociedad, //cobroL.codigo_empresa,
                                     Fecha_Cobro__c = fechaCobro,
                                     numero_serie__c = cobroL.numero_serie,
                                     Ejercicio__c = Integer.valueOf(cobroL.ejercicio),
                                     codigo_cliente__c = cobroL.codigo_cliente,
                                     nombre_cliente__c = cobroL.nombre_cliente,
                                     Importe_Cobrado__c = Decimal.valueOf(cobroL.importe_cobrado),
                                     Numero_Factura__c = cobroL.numero_factura);

                codigosCliente.add(cobroL.codigo_cliente);
                pc = findPedidoSF(pedidos, sociedad, cobroL.numero_factura, cobroL.ejercicio);
                if(pc != null) {
                    cobro.Pedido__c = pc.Id;
                }
                cobrosLibra.add(cobro);
                System.debug(sociedad + ',' + cobroL.numero_factura + ',' + cobroL.ejercicio + ',' + cobroL.importe_cobrado + ',' + cobroL.fecha_cobro);
            }
        }

        codigoClienteMap = getMapClientes(codigosCliente);

        for(Cobro__c cobroLibra : cobrosLibra) {
            cliente = codigoClienteMap.get(cobroLibra.codigo_cliente__c);
            if(cliente != null) {
                cobroLibra.Cliente__c = cliente.Id;
            }
        }

        //insert cobrosLibra;
        //updateCS();

        if(resultCobros != null) {
            System.debug('pedidos.size[' + pedidos.size() + '] cobrosLibra[' + resultCobros.cobros.size() + ']');
        }
        return cobrosLibra;
    }

    public override String buildEndpoint()
    {
        String endpoint;
        endpoint = CS_ENDPOINT + '?' + PARAM_USER + '=' + CS_USER + '&' + PARAM_PWD + '=' + CS_PASS + '&' + PARAM_ALIAS + '=' + CS_ALIAS;
        return endpoint;
    }

    private void updateCS()
    {
        libraCPCS.Fecha_Callout_Exitosa__c = Datetime.now();
        update libraCPCS;
    }


    private PedidoDeCompra__c findPedidoSF(List<PedidoDeCompra__c> pedidos, String pcodigoEmpresaLibra, String pnumeroFacturaLibra, String pejercicio) {
        String sociedadSF;
        String numSociedad;
        PedidoDeCompra__c result;

        String numFac;
        String strFinalEj;
        Integer strLength;
        String facturaEjercicioNumero;
        String[] tokens;
        String strEj;
        Integer numbEj;
        Integer finalEj;

        for(PedidoDeCompra__c pc : pedidos) {
            sociedadSF = pc.Proforma__r.Cuenta__r.Parent.Sociedad__c;
             
            System.debug('[' + pc.Name + ']');

            if(sociedadSF.equals(DO_CORE)) {
                numSociedad = DO_CORE_NUM;
            } else  {
                numSociedad = DO_AMERICA_NUM;
            }

            System.debug('pc.Numero_de_Factura__c [' + pc.Numero_de_Factura__c + ']');

            strLength = pc.Numero_de_Factura__c.length();           

            if(strLength >= 6) {
                facturaEjercicioNumero = pc.Numero_de_Factura__c.substring(strLength - 6);
                tokens = facturaEjercicioNumero.split('/');
                if(tokens.size() == 2) {
                    strEj = tokens[0]; // en FCO19/765 strEj = 19
                    numFac = tokens[1]; // en FCO19/765 numFac = 765
                    numbEj = Integer.valueOf(strEj);
                    finalEj = 2000 + numbEj;
                    strFinalEj = String.valueOf(finalEj);
                    System.debug('strEj[' + strEj + '] numFac[' + numFac + '] numbEj[' + numbEj + '] strFinalEj[' + strFinalEj + ']');
                }
            }
            
            Integer intNumFac = Integer.valueOf(numFac);
            Integer intNumFacLibra = Integer.valueOf(pnumeroFacturaLibra);
            if(numSociedad.equals(pcodigoEmpresaLibra) && intNumFac == intNumFacLibra && strFinalEj.equals(pejercicio)) {
                result = pc;
                break;
            }
        }
        return result;
    }

    private Map<String, Account> getMapClientes(List<String> codigosCliente) {
        RecordType rt;
        Map<String, Account> mapCodigoCliente = new Map<String, Account>();
        List<Account> clientes;
        rt = DOBrandsDAO.getRecordType('Cliente', 'Account');
        clientes = DOBrandsDAO.getAccountByCodigoRapido(codigosCliente, rt);
        for(Account cli : clientes) {
            mapCodigoCliente.put(cli.Codigo_rapido__c, cli);
        }
        return mapCodigoCliente;
    }


}