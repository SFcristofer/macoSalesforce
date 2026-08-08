public class ContainerAddItems {
    private Id estudioPro;
    private Proforma__c pro;
    public list<ContainerItem> containerItems{get;set;}
     
    final String C20 = '20 pies';
    public String getC20() { return C20; }
    final String C40 = '40 pies';
    public String getC40() { return C40; }
    final String C40_HC = '40 pies HC';
    public String getC40_HC() { return C40_HC; }
    
    public Double C20_FT_MAX_CBM {get;set;}
    public Double C40_FT_MAX_CBM {get;set;}
    public Double C40_FT_HC_MAX_CBM {get;set;}
    
    private final String CBM_ERROR = 'El CBM para los items seleccionados ({0}CBM), supera el maximo para tipo de contenedor {1}({2}CBM).';
    
    private final static Decimal MAX_AMOUNT = 80000;
    private final static Decimal MIN_MARGIN = 16;
    
    public Double volume {get;set;}
    public Decimal totalAmount {get;set;}

    public Decimal totalCreditoPedidos {get;set;}
    public Decimal totalCreditoCuenta {get;set;}
    public Decimal estadoDeCredito {get;set;}
    public String styleEstadoCredito {get;set;}

    public List<System.SelectOption> optionsCType {get;set;}
    public String selectedCType {get;set;}
    
    public List<ClosedContainerData> closedContainers{get;set;}
    private Decimal conversionRate;
    private Condiciones_Aprobacion__mdt approveConditions;
    
    /**
    *   Constructor
    */
    public ContainerAddItems(ApexPages.StandardController std){
        String accountId;
        Double cr;
        for(CBM_Contenedores__mdt cbm : [SELECT Tipo__c,
                                                CBM__c
                                                FROM CBM_Contenedores__mdt]){
           if(cbm.Tipo__c == C20){
               C20_FT_MAX_CBM = cbm.CBM__c;
           }else if(cbm.Tipo__c == C40){
               C40_FT_MAX_CBM = cbm.CBM__c;
           }else if(cbm.Tipo__c == C40_HC){
               C40_FT_HC_MAX_CBM = cbm.CBM__c;
           }                       
        }

        approveConditions = getConditions();
    
        pro = fetchProforma(std.getId());
        conversionRate = CurrencyUtil.getRate(pro.CurrencyIsoCode);

        estudioPro = pro.EstudioOportunidad__c;
        containerItems = fetchEstudioItems(estudioPro);
        
        accountId = pro.Cuenta__r.ParentId;
        totalCreditoCuenta = pro.Cuenta__r.Parent.Credito_autorizado__c;
      
        if(pro.Cuenta__r.Parent.CurrencyIsoCode == 'EUR') {
            conversionRate = CurrencyUtil.getRate(pro.CurrencyIsoCode);
            totalCreditoCuenta = totalCreditoCuenta / conversionRate;
        }

        if(totalCreditoCuenta == null) {
            totalCreditoCuenta = 0;
        }

        volume = 0;
        totalAmount = 0;
        
        styleEstadoCredito = 'color:green';
        AprobacionCrediticiaController acc = new AprobacionCrediticiaController(accountId);
        totalCreditoPedidos = acc.balancePedidos;
        estadoDeCredito = totalCreditoCuenta - (totalCreditoPedidos + totalAmount);
        if(estadoDeCredito < 0) {
           styleEstadoCredito = 'color:red';
        }

        optionsCType = new List<SelectOption>{new SelectOption(C20, C20),
                                            new SelectOption(C40, C40),
                                            new SelectOption(C40_HC, C40_HC)};
        
        closedContainers = parseClosedContainers(pro.ProformaLineItems__r);
        totalAmount = pro.ImporteTotal__c;
    }
    
    /**
     * 
     */
    public PageReference save(){
        RecordType rt;        
        list<ProformaLineItem__c> assignContainer = new list<ProformaLineItem__c>();
        Double partialVolume = 0;
        totalAmount = 0;
        Virtual_Container__c vc = new Virtual_Container__c(Tipo__c = selectedCType);
        insert vc;
        for (ContainerItem ci : containerItems){
            if(ci.selected){
                //Modified to account for previous modifications to Costs and Prices on a Simulation
                assignContainer.add(new ProformaLineItem__c(Id = ci.pli == null? null : ci.pli.Id,
                                                        NumeroDeCajas__c = ci.numBoxes,
                                                        Proforma__c = pro.id,
                                                        Producto__c = ci.oli.Product2Id,
                                                        PrecioUnitario__c = ci.closedPrice,
                                                        CostoFabrica__c = ci.closedCost,
                                                        CostoExtraUnitario__c = ci.closedExtraCosts,
                                                        UnidadesPorMasterbox__c = ci.oli.Product2.Unidades_por_Masterbox2__c,
                                                        CBMMasterBox__c = ci.oli.Product2.MasterboxM3_2__c,
                                                        Aportaciones_2__c = ci.oli.Aportaciones_2__c,
                                                        Convenio_2__c = ci.oli.Convenio_2__c,
                                                        Porcentaje_Item__c = ci.oli.Porcentaje_Item__c,
                                                        VirtualContainer__c = vc.Id,
                                                        CurrencyISOCode = pro.CurrencyISOCode));
                partialVolume += ci.oli.Product2.MasterBoxM3_2__c * ci.numBoxes;
                totalAmount += ci.closedPrice * ci.numBoxes
                                                * ci.oli.Product2.Unidades_por_Masterbox2__c;
            }
        }
        if(partialVolume > getSelCBM(selectedCType)){
            ApexPages.Message myMsg = new ApexPages.Message(
                                                ApexPages.Severity.ERROR,
                                                CBM_ERROR.replace('{0}', String.valueof(partialVolume))
                                                .replace('{1}', pro.TipoDeContenedor__c)
                                                .replace('{2}', String.valueof(getSelCBM(selectedCType))));
            ApexPages.addMessage(myMsg);
            
            volume = partialVolume;
            delete vc;
            return null;
        }
        
        upsert assignContainer;
        
        //Query the Proforma again to get the updated Margin
        pro = fetchProforma(pro.Id);

        estadoDeCredito = totalCreditoCuenta - (totalCreditoPedidos + totalAmount);

        if(estadoDeCredito >= 0 && totalAmount < approveConditions.Max_Amount__c && pro.MargenOperacion__c >= approveConditions.Min_Margin__c) {
            createTask(pro);
            //rt = getRecordType('Principal');
            //Requerimiento en el que una proforma siempre debe estar bloqueada al crearse.
            rt = getRecordType('Bloqueada');            
        }else{
            rt = getRecordType('Bloqueada');
            pro.Aprobado_Direccion__c = false;
        }
        pro.RecordTypeId = rt.Id;
        updateContainersCount(selectedCType, pro);

        containerItems = fetchEstudioItems(estudioPro);
        closedContainers = parseClosedContainers(pro.ProformaLineItems__r);
        return null;
    }

    public RecordType getRecordType(String devName)
    {
        //Bloqueada, Principal
        RecordType rt;
        rt = [SELECT Id,
                     Name,
                     DeveloperName
                FROM RecordType
               WHERE SObjectType = 'Proforma__c'
                 AND DeveloperName = :devName];
        return rt;
    }

    private Task createTask(Proforma__c prof)
    {
        // se crea la tarea si no excede el credito
        Task task;
        String ownerIdp;

        if(pro.EstudioOportunidad__c == null)
        {
            return task;
        } 
        if (pro.EstudioOportunidad__r.Oportunidad__c == null)
        {
            return task;
        }

        ownerIdp = prof.EstudioOportunidad__r.Oportunidad__r.OwnerId;
        task = new Task(OwnerId = ownerIdp,
                        Subject = 'Se ha creado una proforma para: ' + prof.EstudioOportunidad__r.Oportunidad__r.Name,
                        Status = 'Open',
                        Priority = 'Normal',
                        ActivityDate = Date.today(),
                        whatId = prof.Id);
        insert task;
        return task;
    }

    private Double getSelCBM(String selectedC) {
        if(selectedC == C40_HC){
            return C40_FT_HC_MAX_CBM;
        }else if(selectedC == C40){
            return C40_FT_MAX_CBM;
        }
        return C20_FT_MAX_CBM;     
    }

    private void updateContainersCount(String selectedC, Proforma__c pro) {
        if(selectedC == C40_HC){
            pro.X40_pies_HC__c += 1;
        } else if(selectedC == C40){
            pro.X40_pies__c += 1;
        } else {
            pro.X20_pies__c += 1;
        }
        update pro;
    }
    /**
     * Calculates ContainerData agregating CBM and Total Price based on Virtual Container Number
     */
    private List<ClosedContainerData> parseClosedContainers(List<ProformaLineItem__c> items) {
        Map<String, ClosedContainerData> closedCMap = new Map<String, ClosedContainerData>();
        for(ProformaLineItem__c item : items) {
            String cntNumber, cntType;
            if(item.VirtualContainer__c == null) {
                cntNumber = 'group';
                cntType =  '****';
            } else {
                cntNumber = item.VirtualContainer__r.Name;
                cntType = item.VirtualContainer__r.Tipo__c;
            }
            ClosedContainerData ccd;
            if(closedCMap.containsKey(item.VirtualContainer__c)) {
                 ccd = closedCMap.get(item.VirtualContainer__c);
            } else {
                ccd = new ClosedContainerData(cntNumber, cntType);
                closedCMap.put(item.VirtualContainer__c, ccd);
            }
            ccd.amount += item.ImporteTotal__c;
            ccd.loadVolume += item.CBMTotal__c;
        }
        return closedCMap.values();
    }

    private Proforma__c fetchProforma(Id proId) {
        return [SELECT Id,
                      Name,
                      CurrencyIsoCode,
                      TipoDeContenedor__c,
                      EstudioOportunidad__c,
                      EstudioOportunidad__r.Oportunidad__c,
                      EstudioOportunidad__r.Oportunidad__r.OwnerId,
                      EstudioOportunidad__r.Oportunidad__r.Name,
                      EstudioOportunidad__r.Oportunidad__r.AccountId,
                      MargenOperacion__c,
                      Cuenta__c,
                      Cuenta__r.Name,
                      Cuenta__r.ParentId,
                      Cuenta__r.Parent.CurrencyIsoCode,
                      Cuenta__r.Credito_autorizado__c,
                      Cuenta__r.Parent.Credito_autorizado__c,
                      RecordTypeId,
                      ImporteTotal__c,
                      X20_pies__c,
                      X40_pies__c,
                      X40_pies_HC__c,
                      (SELECT Id,
                            CBMTotal__c,
                            ImporteTotal__c,
                            VirtualContainer__c,
                            VirtualContainer__r.Name,
                            VirtualContainer__r.Tipo__c
                            FROM ProformaLineItems__r)
                    FROM Proforma__c
                    WHERE Id = :proId];
    }

    public List<ContainerItem> fetchEstudioItems(Id estudioPro) {
        Map<Id, Proforma__c> allProfsStudy = new Map<Id, Proforma__c>([SELECT Id 
                                                                            FROM Proforma__c
                                                                            WHERE EstudioOportunidad__c = :pro.EstudioOportunidad__c]);

        Map<Id, list<ProformaLineItem__c>> prodIdToProformaLI = new Map<Id, list<ProformaLineItem__c>>();
        for(ProformaLineItem__c pli : [SELECT Id,
                                            Name,
                                            Proforma__c,
                                            Proforma__r.Name,
                                            Producto__c,
                                            Producto__r.Name,
                                            NumeroDeCajas__c,
                                            CBMTotal__c,
                                            ImporteTotal__c,
                                            PrecioUnitario__c,
                                            CostoFabrica__c,
                                            CostoExtraUnitario__c
                                            FROM ProformaLineItem__c
                                            WHERE Proforma__c IN :allProfsStudy.keySet()]){

            if(!prodIdToProformaLI.containsKey(pli.Producto__c)){
                prodIdToProformaLI.put(pli.Producto__c, new list<ProformaLineItem__c>{pli});
            }else{
                prodIdToProformaLI.get(pli.Producto__c).add(pli);
            }
        }

        containerItems = new List<ContainerItem>();
        for(OpportunityLineItem oli : [SELECT Id,
                                        Name,
                                        Product2Id,
                                        Product2.MasterboxM3_2__c,
                                        Quantity,
                                        Product2.PrecioDeFabrica__c,
                                        Product2.CostoPackaging__c,
                                        Product2.CostoImportacionUnidad__c,
                                        Producto_Packaging__r.CostoPackaging__c,
                                        CostoProducto__c,
                                        UnitPrice,
                                        TotalPrice,
                                        Product2.Unidades_por_Masterbox2__c,
                                        Codigo_de_Producto__c,
                                        Product2.Descripcion_Larga__c,
                                        Imagen__c,
                                        Aportaciones_2__c,
                                        Convenio_2__c,
                                        Porcentaje_Item__c
                                        FROM OpportunityLineItem
                                        WHERE EstudioOportunidad__c = :estudioPro]){
            boolean added = false;
            list<ProformaLineItem__c> oliPlis = prodIdToProformaLI.get(oli.Product2Id);
            containerItems.add(new ContainerItem(oli, oliPlis, conversionRate));
        }
        return containerItems;
    }

    public Integer getClosedContainersNum() {
        return closedContainers.size();
    }

    private Condiciones_Aprobacion__mdt getConditions() {
        Condiciones_Aprobacion__mdt approveConditionsCS;
 
        approveConditionsCS = [SELECT Id, 
                                      MasterLabel, 
                                      Max_Amount__c,
                                      Min_Margin__c
                                 FROM Condiciones_Aprobacion__mdt LIMIT 1];
    
        return approveConditionsCS;
    }

/**************** PUBLIC CLASES ****************/

    public class ContainerItem{
        public OpportunityLineItem oli {get;set;}
        public boolean selected{get;set;}
        public Integer numBoxes{get;set;}
        public ProformaLineItem__c pli{get;set;}
        //With the addition of multiple containers, now we report the total served, even for this proforma
        public list<ProformaLineItem__c> servedItems{get;set;}
        //If a (potentially modified) Product was previously added to the Proforma, 
        //the UnitPrice and costs of such product will stay as they were in Profroma Line Item
        public Decimal closedPrice {get;set;}
        public Decimal closedCost {get;set;}
        public Decimal closedExtraCosts {get;set;}
        public boolean modifPrice {get;set;}
        public boolean modifCost {get;set;}
        public boolean modifExtraCosts {get;set;}
        private Decimal costoPackaging;

        public ContainerItem(OpportunityLineItem oli, list<ProformaLineItem__c> lpli, Decimal currConversionRate) {
            this.oli = oli;
            selected = false;
            numBoxes = 0;
            servedItems = lpli;
            closedPrice = oli.UnitPrice;
            if(oli.Producto_Packaging__c != null) {
                costoPackaging = oli.Producto_Packaging__r.CostoPackaging__c;
            } else {
                costoPackaging = oli.Product2.CostoPackaging__c;
            }
            closedCost = (oli.Product2.PrecioDeFabrica__c + costoPackaging) * currConversionRate;
            closedExtraCosts = (oli.Product2.CostoImportacionUnidad__c) * currConversionRate;
        }

        public Integer getPending() {
            Integer served = 0;
            if(servedItems != null) {
                for(ProformaLineItem__c pliIter : servedItems){
                    served += (Integer)pliIter.NumeroDeCajas__c;
                }
            }
            if(oli.Product2.Unidades_por_Masterbox2__c == 0) {
                return 0;
            }
            return (Integer)Math.ceil(oli.Quantity/oli.Product2.Unidades_por_Masterbox2__c) - served;
        }
    }

    public class ClosedContainerData {
        public String vcNumber {get;set;}
        public Decimal amount {get;set;}
        public Double loadVolume {get;set;}
        public String vcType {get;set;}

        public ClosedContainerData(String n, String t){
            vcNumber = n;
            vcType = t;
            amount = 0;
            loadVolume = 0;
        }
    }


}