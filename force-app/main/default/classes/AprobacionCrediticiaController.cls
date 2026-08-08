public class AprobacionCrediticiaController {
    public Decimal balancePedidos {set; get;}
    public Decimal totalCreditoCuenta {set; get;}

    /**
     * Constructor
     * @param idAccount this value must be the parent Account identifier
     */
    public AprobacionCrediticiaController(String idAccount) {
        Account account;
        List<Proforma__c> proformas;
        List<PedidoDeCompra__c> pedidos;
		List<String> idsProforma;
        List<String> numerosFacturaPedidos;
        List<Cartera_Importe__c> importesCobradosLibra;

        account = getAccount(idAccount);
		//get pedidos por cuenta
        pedidos = getPedidos(idAccount);
        importesCobradosLibra = getAllPendingAmountsByParent(idAccount);
        balancePedidos = getBalance(pedidos, importesCobradosLibra, account.CurrencyIsoCode);

        totalCreditoCuenta = account.Credito_autorizado__c;
    }


    public List<PedidoDeCompra__c> getPedidos(String idAccount) {
        List<PedidoDeCompra__c> pedidos;
        Date dateToday = Date.today();
        Date todayMinusTwoYears = dateToday.addYears(-2);

		pedidos = [SELECT Id,
                          Name,
                          Precio_Total__c,
                          Cuenta__c,
                          Proforma__r.Cuenta__c,
                          Proforma__c,
                          Fecha_Factura__c,
                          Numero_de_Factura__c,
                          RecordTypeId
                     FROM PedidoDeCompra__c
                    WHERE RecordType.DeveloperName = 'Principal'
                      AND Proforma__r.Cuenta__r.ParentId = :idAccount
                      AND Proforma__r.Oportunidad__r.Fecha_de_Compromiso__c > :todayMinusTwoYears
                      AND Fecha_Factura__c = null
                      AND Factura_Venta_Enviada__c = false];
        return pedidos;
	}


    public Decimal getBalance(List<PedidoDeCompra__c> ppedidos, List<Cartera_Importe__c> pcobroslibra, String isoCode) {
        Decimal balance;
        Decimal sumaPedidosEnProduccion = 0;
        Decimal sumaImportePendiente = 0;

        for(PedidoDeCompra__c pedido : ppedidos) {
            sumaPedidosEnProduccion = sumaPedidosEnProduccion + pedido.Precio_Total__c;
        }

        for(Cartera_Importe__c ci : pcobroslibra) {
            sumaImportePendiente = sumaImportePendiente + ci.Importe_Pendiente_USD__c;
        }
        balance = sumaPedidosEnProduccion + sumaImportePendiente;
        return balance;
    }


    public Account getAccount(String idAccount) {
        Account account;
        account = [SELECT Id, 
                          Name, 
                          CurrencyIsoCode,
                          Credito_autorizado__c
                     FROM Account
                    WHERE Id = :idAccount];
        return account;
    }


    public List<Cartera_Importe__c> getAllPendingAmountsByParent(String idAccount) {
        List<Cartera_Importe__c> importes;
        importes = [SELECT Id, 
                           Cuenta__c,
                           Importe_Pendiente_EUR__c,
                           Importe_Pendiente_USD__c
                      FROM Cartera_Importe__c
                     WHERE Cuenta__c = :idAccount];
        return importes;
    }

}