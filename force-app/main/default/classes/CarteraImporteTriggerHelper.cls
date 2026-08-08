public class CarteraImporteTriggerHelper {
    public static final String INS = 'ins';

    private String operation;
    List<Cartera_Importe__c> newCarteraImporteRecords;


    public CarteraImporteTriggerHelper(List<Cartera_Importe__c> insertedRecords, String oper) {
        newCarteraImporteRecords = insertedRecords;
        operation = oper;
    }


    public void execute() {
        List<String> idsAccount;
        List<PedidoDeCompra__c> orders;
        List<Cartera_Importe__c> pendingAmounts;
        List<Account> accountsToUpdate;
        Decimal sumProductionOrders = 0;
        Decimal sumPendingAmounts = 0;
        Account acc;
        Decimal authorizedCredit;

        Map<String, List<PedidoDeCompra__c>> parentAccountOrders;
        Map<String, List<Cartera_Importe__c>> parentPendingAmounts;
        Map<String, Account> parentIdAccountMap;
        
        accountsToUpdate = new List<Account>();
        idsAccount = new List<String>();

        for(Cartera_Importe__c cir : newCarteraImporteRecords) {
            //only customer data is used to update balance
            if(cir.Tipo_Archivo__c.equals('Customer')) {
                idsAccount.add(cir.Cuenta__c);
            }
        }

        parentPendingAmounts = getAllPendingAmountsByParent(newCarteraImporteRecords);
        parentIdAccountMap = getParentAccounts();
        parentAccountOrders = getParentAccountsOrders(parentIdAccountMap.keySet());

        if(this.operation == INS && !idsAccount.isEmpty()) {
            for(String idAcc : parentIdAccountMap.keySet()) {

                sumProductionOrders = 0;
                sumPendingAmounts = 0;
                acc = parentIdAccountMap.get(idAcc);

                //sum order price
                orders = parentAccountOrders.get(idAcc);
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

                authorizedCredit = acc.Credito_autorizado__c == null ? 0 : acc.Credito_autorizado__c;
                acc.Balance_Cuenta__c = authorizedCredit - (sumProductionOrders + sumPendingAmounts);
                accountsToUpdate.add(acc);
            }

            update accountsToUpdate;
        }
    }


    public Map<String, List<PedidoDeCompra__c>> getParentAccountsOrders(Set<String> idAccounts) {
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


    public Map<String, List<Cartera_Importe__c>> getAllPendingAmountsByParent(List<Cartera_Importe__c> importes) {
        Map<String, List<Cartera_Importe__c>> mapAccountPendingAmounts = new Map<String, List<Cartera_Importe__c>>();
        List<Cartera_Importe__c> accountPendingAmounts;

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


    public Map<String, Account> getParentAccounts() {
        Map<String, Account> mapIdParentAccount = new Map<String, Account>();
        Map<String, Account> mapIdGrandParentAccount = new Map<String, Account>();
        List<Account> accounts;

        //Get all 'Cliente' accounts
        accounts = [SELECT Id, 
                           Name, 
                           Credito_autorizado__c,
                           Balance_Cuenta__c,
                           RecordType.DeveloperName, 
                           ParentId, 
                           Parent.Name 
                      FROM Account 
                     WHERE RecordType.DeveloperName = 'Cliente' 
                  ORDER BY Name];

        for(Account acc : accounts) {
            mapIdParentAccount.put(acc.Id, acc);
            //filter only grandparent accounts
            if(acc.ParentId != null) {
                mapIdGrandParentAccount.put(acc.parentId, acc);
            }
        }

        //remove grandparent accounts
        for(String idGrandParent : mapIdGrandParentAccount.keySet()) {
            mapIdParentAccount.remove(idGrandParent);
        }

        return mapIdParentAccount;
    }

}