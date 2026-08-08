public class ProformaTriggerHelper{
    public static final String INS = 'ins';
    public static final String UPD = 'upd';
    private static final String SIM = 'Simulacion';
    private static final String OK = 'OK!';
    private static final String PPAL = 'Principal';
    private static final String BLOCK = 'Bloqueada';

    private set<Id> proformaIds;
    private set<Id> estudioOppIds;
    public list<Proforma__c> newProformas;
    public Map<Id, Proforma__c> oldProformas;
    private String oper;
    private list<Proforma__c> toBlock;
    private Id principal, blocked; 
    private boolean isBefore;

    private Escandallo__c escandalloUnico;
    private Map<String, List<Proforma__c>> mapParentAccountProforma;

    public ProformaTriggerHelper(list<Proforma__c> profs, map<Id, Proforma__c> oldProfs, String oper, boolean isBefore){
        this.oper = oper;
        this.isBefore = isBefore;
        oldProformas = oldProfs;

        for(RecordType rt : [SELECT Id,
                                DeveloperName
                                FROM RecordType
                                WHERE sObjectType = 'Proforma__c']){
            if(rt.DeveloperName == PPAL){
                principal = rt.Id;
            }else if(rt.DeveloperName == BLOCK){
                blocked = rt.Id;
            }
        }

        if(oper == INS){
            System.debug('Proforma Trigger Helper oper [' + oper + ']');
            newProformas = new list<Proforma__c>();
            estudioOppIds = new set<Id>();
            
            for(Proforma__c p : profs)
            {
                if(p.Name != null && (p.Name.equals('') || p.Name.contains('Autogenerado')))
                {
                    //p.Name = Util.getIncrement('proforma');
                    p.Name = Util.getIncrement('proforma', p.Planificacion_Comercial__c);
                }
                newProformas.add(p);
                if(p.EstudioOportunidad__c != null){
                    estudioOppIds.add(p.EstudioOportunidad__c);
                }
            }
        }else if(oper == UPD){
            System.debug('Proforma Trigger Helper oper 2 [' + oper + ']');
            newProformas = new list<Proforma__c>();            
            escandalloUnico = getEscandallo();
            proformaIds = new set<Id>();
            toBlock = new list<Proforma__c>();
            for(Proforma__c p : profs){
            
                if(p.EstudioOportunidad__c == null) {
                    //p.addError('La proforma no tiene estudio de oportunidad');
                    System.debug('La proforma [' + p.Name + '] no tiene estudio de oportunidad');
                    throw new IllegalArgumentException('La proforma [' + p.Name + '] no tiene estudio de oportunidad');
                }
                
                if(p.ConfirmacionCliente__c && !oldProfs.get(p.Id).ConfirmacionCliente__c){
                    proformaIds.add(p.Id);
                }
                if(lockCriteria(p, oldProfs)){
                    toBlock.add(p);
                }
                newProformas.add(p);                
            }
        }
    }
    
    public void execute(){
        if(oper == INS){
            executeInsert();
        }else if(oper == UPD && !isBefore){
            executeUpdate();
            executeUpdateOLI();
        }else if(oper == UPD && isBefore){
            executeBeforeUpdate();
        }
    }


    public void executeUpdateOLI() {
        List<String> proformaApporvedIDs = new List<String>();
        for(Proforma__c proforma : newProformas) {
            if(validateApprovedProforma(proforma)) {
                proformaApporvedIDs.add(proforma.Id);
            }
        }
        processApprovedProformas(proformaApporvedIDs);
    }

    public void executeInsert(){
        map<Id, EstudioOportunidad__c> estudioToOpp = new map<Id, EstudioOportunidad__c>([SELECT Id,
                                                                                        Oportunidad__c,
                                                                                        Oportunidad__r.AccountId
                                                                                        FROM EstudioOportunidad__c
                                                                                        WHERE Id in :estudioOppIds]);
        for(Proforma__c p : newProformas){
            if(p.EstudioOportunidad__c != null){
                p.Oportunidad__c = estudioToOpp.get(p.EstudioOportunidad__c).Oportunidad__c;
                p.Cuenta__c = estudioToOpp.get(p.EstudioOportunidad__c).Oportunidad__r.AccountId;
                //cambio para boton simular pedido
                p.RecordTypeId = blocked;
                System.debug('PR TR HLPR XCXCXCX [' + p.Id + '] [' + p.Cuenta__c + ']');
            }
        }
    }

    public void executeUpdate(){
        Map<Id, PedidoDeCompra__c> newPedidos = new Map<Id, PedidoDeCompra__c>();
        List<PedidoDeCompra__c> oldSimulations = new List<PedidoDeCompra__c>();
        List<PedidoLineItem__c> newPedidoLineItems = new List<PedidoLineItem__c>();
        mapParentAccountProforma = new Map<String, List<Proforma__c>>();
        List<Proforma__c> listProformas;
        String mapKey;

        for(Proforma__c p : [SELECT Id,
                                TipoDeContenedor__c,
                                Aprobado_Direccion__c,                                
                                ETD__c,
                                Cuenta__r.PlazoPago__c,
                                Cuenta__r.ParentId,
                                ConfirmacionCliente__c,                                
                                Cuenta__r.Parent.PlazoPago__c,
                                ImporteTotal__c,
                                EstudioOportunidad__r.Fabrica__c,
                                EstudioOportunidad__r.Fabrica__r.PorcentajeDeposito__c,
                                EstudioOportunidad__r.Fabrica__r.TiempoServicioMedio__c,
                                EstudioOportunidad__r.Fabrica__r.PlazoPago__c,
                                EstudioOportunidad__r.Fabrica__r.Puerto__c,
                                EstudioOportunidad__r.Fabrica__r.EmailComercial__c,
                                Cuenta__r.Puerto__c,
                                (SELECT Id,
                                    PorcentajeDepositoAFabrica__c,
                                    PlazoFabricacion__c,
                                    PlazoPagoFab__c,
                                    TipoDeInteresDepositoFabrica__c,
                                    PlazoPago__c,
                                    TipoDeInteresFinanciacionClient__c,
                                    CambioDocumentsXHQ__c,
                                    CertificadoOrigen__c,
                                    InspeccionXEntrega__c,
                                    NroInspecciones__c,
                                    Muestras__c,
                                    ComisionAdministrativa__c
                                    FROM PedidosDeCompra__r
                                    WHERE RecordType.DeveloperName = :SIM)
                                FROM Proforma__c
                                WHERE Id in :proformaIds]){

            mapKey = p.Cuenta__r.ParentId;
            if(mapParentAccountProforma.containsKey(mapKey)) {
                listProformas = mapParentAccountProforma.get(mapKey);
                listProformas.add(p);
            } else {
                mapParentAccountProforma.put(mapKey, new List<Proforma__c>{p});
            }
            
            //if(p.EstudioOportunidad__r == null) {
            //    p.addError('La proforma no tiene estudio de oportunidad');
            //}

            PedidoDeCompra__c newPedido = new PedidoDeCompra__c(Proforma__c = p.Id,
                                                    Name = '[Pend. Asignación]',
                                                    Proveedor__c = p.EstudioOportunidad__r.Fabrica__c,
                                                    PlazoPago__c = p.Cuenta__r.PlazoPago__c == null? Integer.valueOf(p.Cuenta__r.Parent.PlazoPago__c) 
                                                                    :Integer.valueOf(p.Cuenta__r.PlazoPago__c),
                                                    PlazoPagoFab__c = Integer.valueOf(p.EstudioOportunidad__r.Fabrica__r.PlazoPago__c),
                                                    Email_Fabrica__c = p.EstudioOportunidad__r.Fabrica__r.EmailComercial__c,
                                                    PlazoFabricacion__c = Integer.valueOf(p.EstudioOportunidad__r.Fabrica__r.TiempoServicioMedio__c),
                                                    PorcentajeDepositoAFabrica__c = Integer.valueOf(p.EstudioOportunidad__r.Fabrica__r.PorcentajeDeposito__c),
                                                    FechaConfirmacionCliente__c = Date.today(),
                                                    Puerto_de_destino__c = p.Cuenta__r.Puerto__c,
                                                    Puerto_de_origen__c = p.EstudioOportunidad__r.Fabrica__r.Puerto__c,
                                                    TipoDeInteresFinanciacionClient__c = escandalloUnico.TipoDeInteresFinanciacionClient__c,
                                                    TipoDeInteresDepositoFabrica__c = escandalloUnico.TipoDeInteresDepositoFabrica__c,
                                                    InspeccionXEntrega__c = escandalloUnico.InspeccionXEntrega__c,
                                                    CambioDocumentsXHQ__c = escandalloUnico.CambioDocumentsXHQ__c);

            if(p.PedidosDeCompra__r.size() == 1){
                newPedido.PorcentajeDepositoAFabrica__c = p.PedidosDeCompra__r[0].PorcentajeDepositoAFabrica__c;
                newPedido.PlazoFabricacion__c = p.PedidosDeCompra__r[0].PlazoFabricacion__c;
                newPedido.PlazoPagoFab__c = p.PedidosDeCompra__r[0].PlazoPagoFab__c;
                newPedido.TipoDeInteresDepositoFabrica__c = p.PedidosDeCompra__r[0].TipoDeInteresDepositoFabrica__c;
                newPedido.PlazoPago__c = p.PedidosDeCompra__r[0].PlazoPago__c;
                newPedido.TipoDeInteresFinanciacionClient__c = p.PedidosDeCompra__r[0].TipoDeInteresFinanciacionClient__c;
                newPedido.CambioDocumentsXHQ__c = p.PedidosDeCompra__r[0].CambioDocumentsXHQ__c;
                newPedido.CertificadoOrigen__c = p.PedidosDeCompra__r[0].CertificadoOrigen__c;
                newPedido.InspeccionXEntrega__c = p.PedidosDeCompra__r[0].InspeccionXEntrega__c;
                newPedido.NroInspecciones__c = p.PedidosDeCompra__r[0].NroInspecciones__c;
                newPedido.Muestras__c = p.PedidosDeCompra__r[0].Muestras__c;
                newPedido.ComisionAdministrativa__c = p.PedidosDeCompra__r[0].ComisionAdministrativa__c;
                oldSimulations.add(p.PedidosDeCompra__r[0]);
            }
            newPedidos.put(p.Id,
                            newPedido);
        }
        
        insert newPedidos.values();
        delete oldSimulations;

        for(Proforma__c p : [SELECT Id,
                                CurrencyISOCode,
                                (SELECT Id,
                                    NumeroDeCajas__c,
                                    Producto__c,
                                    Producto__r.PrecioDeFabrica__c,
                                    Producto__r.CostoPackaging__c,
                                    UnidadesPorMasterBox__c,
                                    CBMMasterBox__c,
                                    PrecioUnitario__c,
                                    CostoFabrica__c,
                                    Aportaciones_2__c,
                                    Convenio_2__c,
                                    Porcentaje_Item__c
                                    FROM ProformaLineItems__r)
                                FROM Proforma__c
                                WHERE Id in :proformaIds]){
            Decimal rate = CurrencyUtil.getRate(p.CurrencyISOCode);
            for(ProformaLineItem__c pli : p.ProformaLineItems__r){
                newPedidoLineItems.add(new PedidoLineItem__c(ProformaLineItem__c = pli.Id,
                                                            PedidoDeCompra__c = newPedidos.get(p.Id).Id,
                                                            NumeroDeCajas__c = pli.NumeroDeCajas__c,
                                                            CostoOrigen__c = p.CurrencyISOCode == CurrencyUtil.USD ? pli.CostoFabrica__c : (pli.CostoFabrica__c / rate).setScale(2, RoundingMode.HALF_UP), //multiply by conversion rate round up to 2 decimals
                                                            UnidadesPorMasterBox__c = pli.UnidadesPorMasterBox__c,
                                                            CBMMasterBox__c = pli.CBMMasterBox__c,
                                                            PrecioDeVenta__c = p.CurrencyISOCode == CurrencyUtil.USD ? pli.PrecioUnitario__c : (pli.PrecioUnitario__c / rate).setScale(2, RoundingMode.HALF_UP), //multiply by conversion rate round up to 2 decimals
                                                            Producto__c = pli.Producto__c,
                                                            Aportaciones_2__c = pli.Aportaciones_2__c,
                                                            Convenio_2__c = pli.Convenio_2__c,
                                                            Porcentaje_Item__c = pli.Porcentaje_Item__c));
            }
        }
        insert newPedidoLineItems;

        updateBalanceAccounts(mapParentAccountProforma);
    }

    /**
    *   Locks any Proforma__c which no longer meets criteria
    */
    private void executeBeforeUpdate(){
        List<String> proformaApprovedIDs = new List<String>();
        for(Proforma__c p : toBlock){
            p.Aprobado_Direccion__c = false;
            p.RecordTypeId = blocked;
        }

    }

    private boolean lockCriteria(Proforma__c p, Map<Id, Proforma__c> oldP){
        if(p.Alerta_Margen__c == null){
            return false; //Added for reparenting PedidoLineItems
        }
        if(p.RecordTypeId == principal &&
            ((!p.Alerta_Margen__c.contains(OK) && oldP.get(p.Id).Alerta_Margen__c.contains(OK))
            || (!p.Alerta_Credito__c.contains(OK) && oldP.get(p.Id).Alerta_Credito__c.contains(OK))
            || (!p.Alerta_Importe__c.contains(OK) && oldP.get(p.Id).Alerta_Importe__c.contains(OK)))){
            return true;
        }
        return false;
    }

    private Escandallo__c getEscandallo() {
        Escandallo__c escandallo;
        escandallo = [SELECT Id, 
                             TipoDeInteresDepositoFabrica__c, 
                             TipoDeInteresFinanciacionClient__c,
                             InspeccionXEntrega__c,
                             CambioDocumentsXHQ__c
                        FROM Escandallo__c 
                       WHERE Name = 'Único'];
        return escandallo; 
    }


    private void processApprovedProformas(List<String> idsProformas) {

        ProformaLineItem__c proformaLI;
        OpportunityLineItem opportunityLI;

        List<Proforma__c> proformas;
        List<ProformaLineItem__c> proformaItems;
        List<String> idsOpportunities;
        List<String> proformaProductCodes;
        //Map of opportunity-productcode, proformalineitem
        Map<String, ProformaLineItem__c> mapOppPCodeProformaLI;
        //Map of opportunity-productcode, opportunitylineitem
        Map<String, OpportunityLineItem> mapOppPCodeOppLI;
        List<OpportunityLineItem> opportunityLineItems;

        idsOpportunities = new List<String>();
        proformaProductCodes = new List<String>();
        mapOppPCodeProformaLI = new Map<String, ProformaLineItem__c>();
        opportunityLineItems = new List<OpportunityLineItem>();

        //get proformas approved
        proformas = DOBrandsDAO.getProformas(idsProformas);
        for(Proforma__c proforma : proformas) {
            idsOpportunities.add(proforma.Oportunidad__c);
            proformaItems = proforma.ProformaLineItems__r;
            for(ProformaLineItem__c proformaLineItem : proformaItems) {
                proformaProductCodes.add(proformaLineItem.Codigo_de_Producto__c);
                mapOppPCodeProformaLI.put(proforma.Oportunidad__c + '-' + proformaLineItem.Codigo_de_Producto__c, proformaLineItem);
            }
        }

        mapOppPCodeOppLI = DOBrandsDAO.getOpportunityLineItems(idsOpportunities, proformaProductCodes);

        for(String oppPCode : mapOppPCodeProformaLI.keySet()) {
            proformaLI = mapOppPCodeProformaLI.get(oppPCode);
            opportunityLI = mapOppPCodeOppLI.get(oppPCode);
            if(opportunityLI != null) {
                opportunityLI.CostoProducto__c = proformaLI.CostoTotalUnitario__c;
                opportunityLineItems.add(opportunityLI);
            }
        }

        update opportunityLineItems;
    }


    private void updateBalanceAccounts(Map<String, List<Proforma__c>> mapAccountsProforma) {
        Map<String, List<PedidoDeCompra__c>> parentAccountOrders;
        Map<String, List<Cartera_Importe__c>> parentPendingAmounts;
        List<Account> parentAccounts;
        List<PedidoDeCompra__c> orders;
        List<Cartera_Importe__c> pendingAmounts;
        List<Proforma__c> proformas;
        Decimal sumProductionOrders;
        Decimal sumPendingAmounts;
        Decimal sumProformaAmounts;

        System.debug('Updating account balance');

        //get all parent accounts
        parentAccounts = getProformaParentAccounts(mapAccountsProforma.keySet());
        parentAccountOrders = getParentAccountsOrders(mapAccountsProforma.keySet());
        parentPendingAmounts = getAllPendingAmountsByParent(mapAccountsProforma.keySet());

        List<Proforma__c> deleteThisTest;
        for(String keyM : mapAccountsProforma.keySet()) {
            System.debug('idparent[' + keyM + ']');
            for(Proforma__c pt : mapAccountsProforma.get(keyM)) {
                System.debug('---- idpr[' + pt.Id + '] m[' + pt.ImporteTotal__c + ']');
            }
        }

        for(Account parentAcct : parentAccounts) {

            sumProductionOrders = 0;
            sumPendingAmounts = 0;
            sumProformaAmounts = 0;

            //sum order price
            orders = parentAccountOrders.get(parentAcct.Id);
            if(orders != null) {
                for(PedidoDeCompra__c o : orders) {
                    sumProductionOrders = sumProductionOrders + o.Precio_Total__c;
                }
            }

            //sum pending amount
            pendingAmounts = parentPendingAmounts.get(parentAcct.Id);
            if(pendingAmounts != null) {
                for(Cartera_Importe__c pa : pendingAmounts) {
                    sumPendingAmounts = sumPendingAmounts + pa.Importe_Pendiente_USD__c;
                }
            }

            //sum proforma total
            proformas = mapAccountsProforma.get(parentAcct.Id);
            if(proformas != null) {
                for(Proforma__c pr : proformas) {
                    sumProformaAmounts = sumProformaAmounts + pr.ImporteTotal__c;
                }
            }
            //LAST FINDING: JUNE 9 sumProformaAmounts must not be added since we already have the proforma added in sumProductionOrders
            System.debug('credaut[' + parentAcct.Credito_autorizado__c + '] sumord[' + sumProductionOrders + '] sumpend[' + sumPendingAmounts + '] sumprof[' + sumProformaAmounts + '] acctPar[' + parentAcct.Id + ']');
            parentAcct.Balance_Cuenta__c = parentAcct.Credito_autorizado__c - (sumProductionOrders + sumPendingAmounts + sumProformaAmounts);
        }

        update parentAccounts;
    }

    /**
     * Validates if a proforma has been approved
     */
    private Boolean validateApprovedProforma(Proforma__c proforma) {
        Proforma__c oldProforma = oldProformas.get(proforma.Id);
        if(proforma.ConfirmacionCliente__c && oldProforma.ConfirmacionCliente__c == false) {
            return true;
        }
        return false;
    }


    public List<Account> getProformaParentAccounts(Set<String> accountIds) {
        List<Account> parentAccounts;

        parentAccounts = [SELECT Id, 
                                 Name, 
                                 CurrencyIsoCode,
                                 Credito_autorizado__c,
                                 Balance_Cuenta__c
                            FROM Account
                           WHERE Id IN :accountIds];
        return parentAccounts;
    }
    

    public Map<String, List<PedidoDeCompra__c>> getParentAccountsOrders(Set<String> idAccounts) {
        Map<String, List<PedidoDeCompra__c>> mapParentAccountOrders = new Map<String, List<PedidoDeCompra__c>>();
        List<PedidoDeCompra__c> orders;
        List<PedidoDeCompra__c> accountOrders;
        String keyMap;
        Date dateToday = Date.today();
        Date dateTodayMinusYear = dateToday.addYears(-2);

        System.debug('today[' + dateToday + '] toda-1y[' + dateTodayMinusYear + ']');

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
                     AND Proforma__r.Cuenta__r.ParentId = :idAccounts
                     AND Fecha_Factura__c = null
                     AND Proforma__r.Oportunidad__r.Fecha_de_Compromiso__c > :dateTodayMinusYear
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
    

    public Map<String, List<Cartera_Importe__c>> getAllPendingAmountsByParent(Set<String> idParentAccounts) {
        Map<String, List<Cartera_Importe__c>> mapAccountPendingAmounts = new Map<String, List<Cartera_Importe__c>>();
        List<Cartera_Importe__c> importes;
        List<Cartera_Importe__c> accountPendingAmounts;

        System.debug('parentids [' + idParentAccounts + ']');

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