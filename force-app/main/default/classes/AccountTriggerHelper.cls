public class AccountTriggerHelper {
    public static final String UPD = 'upd';
    public static final String BEF = 'bef';
    
    private String operation;
    private String afterBeforeOperation;
    
    Map<Id, Account> oldAccountsMap;
    List<Account> newAccounts;


    public static void executeUpdateBefore(List<Account> updatedAccounts, Map<Id, Account> oldMap, String oper, String afterbefop) {
        String operation;
        String afterBeforeOperation;
        Map<Id, Account> oldAccountsMap;
        List<Account> newAccounts;
    
        newAccounts = updatedAccounts;
        operation = oper;
        afterBeforeOperation = afterbefop;
        oldAccountsMap = oldMap;
        
        Decimal ordersCarteraSum;
        Decimal oldAuthorizedCredit;
        Decimal oldBalance;
        Account oldAccount;
        List<String> idsAccount;
        List<PedidoDeCompra__c> orders;
        List<Cartera_Importe__c> pendingAmounts;
        Decimal sumProductionOrders = 0;
        Decimal sumPendingAmounts = 0;

        Map<String, List<PedidoDeCompra__c>> parentAccountOrders;
        Map<String, List<Cartera_Importe__c>> parentPendingAmounts;

        idsAccount = new List<String>();
        
        System.debug(' op[' + operation + '] aftbefop[' + afterBeforeOperation + ']');
        
        if(operation == UPD && afterBeforeOperation == BEF) {
        
            for(Account acc : newAccounts) {
                idsAccount.add(acc.Id);
            }

            parentAccountOrders = getParentAccountsOrders(idsAccount);
            parentPendingAmounts = getAllPendingAmountsByParent(idsAccount);
            
            for(Account acc : newAccounts) {
                //Check if authorized credti has changed
                oldAccount = oldAccountsMap.get(acc.Id);
                if(oldAccount.Credito_autorizado__c != acc.Credito_autorizado__c ) {

                    //sum order price
                    orders = parentAccountOrders.get(acc.Id);
                    if(orders != null) {
                        for(PedidoDeCompra__c o : orders) {
                            sumProductionOrders = sumProductionOrders + o.Precio_Total__c;
                        }
                    }

                    //sum pending amount
                    pendingAmounts = parentPendingAmounts.get(acc.Id);
                    if(pendingAmounts != null) {
                        for(Cartera_Importe__c pa : pendingAmounts) {
                            sumPendingAmounts = sumPendingAmounts + pa.Importe_Pendiente_USD__c;
                        }
                    }
                    acc.Balance_Cuenta__c = acc.Credito_autorizado__c - (sumProductionOrders + sumPendingAmounts);
                }
            }
        }
    }

    public static Map<String, List<PedidoDeCompra__c>> getParentAccountsOrders(List<String> idAccounts) {
        Map<String, List<PedidoDeCompra__c>> mapParentAccountOrders = new Map<String, List<PedidoDeCompra__c>>();
        List<PedidoDeCompra__c> orders;
        List<PedidoDeCompra__c> accountOrders;
        String keyMap;
        Date dateToday = Date.today();
        Date todayMinusTwoYears = dateToday.addYears(-2);

        orders = [SELECT Id,
                         Name,
                         Precio_Total__c,
                         Cuenta__c,
                         Proforma__r.Cuenta__c,
                         Proforma__r.Cuenta__r.ParentId,
                         Proforma__c,
                         Fecha_Factura__c,
                         Numero_de_Factura__c,
                         RecordTypeId
                    FROM PedidoDeCompra__c
                   WHERE RecordType.DeveloperName = 'Principal'
                     AND Proforma__r.Cuenta__r.ParentId IN :idAccounts
                     AND Fecha_Factura__c = null
                     AND Proforma__r.Oportunidad__r.Fecha_de_Compromiso__c > :todayMinusTwoYears
                     AND Factura_Venta_Enviada__c = false];

        for(PedidoDeCompra__c order : orders) {
            keyMap = order.Proforma__r.Cuenta__r.ParentId;
            if(mapParentAccountOrders.containsKey(keyMap)) {
                accountOrders = mapParentAccountOrders.get(keyMap);
                accountOrders.add(order);
            } else {
                mapParentAccountOrders.put(keyMap, new List<PedidoDeCompra__c>{order});
            }
        }
        return mapParentAccountOrders;
    }


    public static Map<String, List<Cartera_Importe__c>> getAllPendingAmountsByParent(List<String> idParentAccounts) {
        Map<String, List<Cartera_Importe__c>> mapAccountPendingAmounts = new Map<String, List<Cartera_Importe__c>>();
        List<Cartera_Importe__c> importes;
        List<Cartera_Importe__c> accountPendingAmounts;

        importes = [SELECT Id, 
                           Cuenta__c,
                           Importe_Pendiente_EUR__c,
                           Importe_Pendiente_USD__c
                      FROM Cartera_Importe__c
                     WHERE Cuenta__c IN :idParentAccounts];

        for(Cartera_Importe__c pendingAmount : importes) {
            if(mapAccountPendingAmounts.containsKey(pendingAmount.Cuenta__c)) {
                accountPendingAmounts = mapAccountPendingAmounts.get(pendingAmount.Cuenta__c);
                accountPendingAmounts.add(pendingAmount);
            } else {
                mapAccountPendingAmounts.put(pendingAmount.Cuenta__c, new List<Cartera_Importe__c>{pendingAmount});
            }
        }
        return mapAccountPendingAmounts;
    }

}