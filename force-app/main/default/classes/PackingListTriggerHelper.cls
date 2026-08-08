/**
*   Helper class for PackingListTrigger
*/
public class PackingListTriggerHelper {
    private List<PackingList__c> targetPLs;
    
    public PackingListTriggerHelper(List<PackingList__c> newRecords, Map<Id, PackingList__c> oldRecMap) {
        List<Id> targetIds = new List<Id>();
        for(PackingList__c pl : newRecords) {
            if(pl.Estado__c == 'Aprobado' && oldRecMap.get(pl.Id).Estado__c != 'Aprobado') {
                targetIds.add(pl.Id);
            }
        }
        targetPLs  = [SELECT Id, 
                             Pedido__c, 
                            (SELECT Id,
                                    Container_Number__c,
                                    SEAL_Number__c,
                                    UnidadesPorMasterbox__c,
                                    Quantity__c,
                                    Producto__r.CodigoDeProductoBase__c
                                    FROM Pedido_Line_Items__r)
                            FROM PackingList__c
                            WHERE Id IN :targetIds];
    }

    /**
    *   For just approved PackingLists sets #Boxes = Qty / Items per Box for all their Items
    *   If any calculation is not an Integer adds an error to the Order Item record
    **/
    public void execute() {
        Set<String> containerNumberSet;
        Set<String> sealNumberSet;
        String containerNumbers;
        String sealNumbers;
        Map<String, String> idOrderContainersMap = new Map<String, String>();
        Map<String, String> idOrderSealsMap = new Map<String, String>();
        String fullContainers;
        String fullSeals;
        List<PedidoDeCompra__c> orders;
        List<PedidoLineItem__c> updPLI = new List<PedidoLineItem__c>();
        boolean hasError = false;
        for(PackingList__c pl : targetPLs) {
            containerNumberSet = new Set<String>();
            sealNumberSet = new Set<String>();
            containerNumbers = '';
            sealNumbers = '';
            for(PedidoLineItem__c pli : pl.Pedido_Line_Items__r) {
                if(pli.Container_Number__c != null) {
                    containerNumberSet.add(pli.Container_Number__c);
                }

                if(pli.SEAL_Number__c != null) {
                    sealNumberSet.add(pli.SEAL_Number__c);
                }

                try {
                    pli.NumeroDeCajas__c = pli.Quantity__c / pli.UnidadesPorMasterbox__c;
                    if(pli.NumeroDeCajas__c - Integer.valueOf(pli.NumeroDeCajas__c) != 0) {
                        trigger.newMap.get(pl.Id).addError('Quantity (' + pli.Quantity__c + ') does not fit the Items per Box (' 
                                        + pli.UnidadesPorMasterbox__c + ') for item ' + pli.Producto__r.CodigoDeProductoBase__c);
                        hasError = true;
                        break;
                    }
                } catch (Exception e) {
                    pl.addError(e.getMessage() + ' for item ' + pli.Producto__r.CodigoDeProductoBase__c);
                    hasError = true;
                    break;
                }
            }
            for(String containerNumberPLI : containerNumberSet) {
                containerNumbers = containerNumbers + containerNumberPLI + ',';
            }

            for(String sealNumberPLI : sealNumberSet) {
                sealNumbers = sealNumbers + sealNumberPLI + ',';
            }

            if(!containerNumbers.equals('')) {
                containerNumbers = containerNumbers.substring(0, containerNumbers.length() - 1);
            }

            if(!sealNumbers.equals('')) {
                sealNumbers = sealNumbers.substring(0, sealNumbers.length() - 1);
            }

            idOrderContainersMap.put(pl.Pedido__c, containerNumbers);
            idOrderSealsMap.put(pl.Pedido__c, sealNumbers);

            updPLI.addAll(pl.Pedido_Line_Items__r);
        }
        if(!hasError) {
            update updPLI;
        }

        orders = getOrders(idOrderContainersMap.keySet());
        for(PedidoDeCompra__c order : orders) {
            fullContainers = idOrderContainersMap.get(order.Id);
            order.NumeroDeContenedor__c = fullContainers;
            fullSeals = idOrderSealsMap.get(order.Id);
            order.N_de_Seal__c = fullSeals;
        }

        update orders;
    }


    private List<PedidoDeCompra__c> getOrders(Set<String> ids) {
        List<PedidoDeCompra__c> orders;
        orders = [SELECT Id,
                         Name,
                         NumeroDeContenedor__c
                FROM PedidoDeCompra__c
                WHERE Id = :ids];
        return orders;
    }
}