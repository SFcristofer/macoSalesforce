public class OppCostVerificationController {
    public Opportunity originalOpportunity {set; get;}
    public List<ProductCostVerification> prods {set; get;}
    public Integer totalProductos {set; get;}
    public Integer totalVerificados {set; get;}
    public Integer totalNoVerificados {set; get;}
    public String accountName {set; get;}
    public List<ProductCostVerification> prodsToVerify;
    public Map<String, String> mapVerificacionProductos;
    public String customMsg {set; get;}    

    public OppCostVerificationController(ApexPages.StandardController stdController) {
        System.debug('STD CNTS');
        originalOpportunity = (Opportunity)stdController.getRecord();
        System.debug('n [' + originalOpportunity.Name + ']');
        getCostVerificationData();        
    }

    public OppCostVerificationController() {
        System.debug('VACIIIOOOOOOOOOOOOOOOOOO');
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Envío exitoso'));
        customMsg = ApexPages.CurrentPage().getparameters().get('res'); 
        System.debug('res[' + customMsg + ']');
    }

    private void getCostVerificationData() {
        String idProd;
        totalVerificados = 0;
        totalNoVerificados = 0;
        List<String> idsOpp = new List<String>();
        List<OpportunityCostVerification> opsCV;
        OpportunityCostVerification oppCV;

        idsOpp.add(originalOpportunity.Id);
        opsCV = OpportunityDAO.getOpportunitiesCostVerification(idsOpp);
        if(opsCV != null && opsCV.size() > 0) {
            oppCV = opsCV.get(0);
            accountName = oppCV.opportunity.Account.Name;
            prods = oppCV.productsCostV;
        }

        totalProductos = prods.size();

        System.debug('--------------------------------------------------------------------------------------------------------------------');

        Map<String, String> mapver = getProductsInVerification();

        for(ProductCostVerification pcv : prods) {
            idProd = mapver.get(pcv.idProduct);
            if(idProd != null) {
                pcv.orderColor = 2;
                pcv.colorBall = '/resource/1560452910000/blueCircle';
                pcv.isSent = true;
            }
            if(pcv.isPrecioVigente) {
                totalVerificados++;
            } else {
                totalNoVerificados ++;
            }
        }

        prods.sort();
    }


    public PageReference verification() {
        PageReference pageRef = new PageReference('/apex/ConfirmacionOppCostVerification?res=2');
        prodsToVerify = new List<ProductCostVerification>();

        for(ProductCostVerification pcv : prods) {
            if(!pcv.isPrecioVigente && !pcv.isSent) {
                prodsToVerify.add(pcv);
            }
        }
        if(prodsToVerify.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'No hay verificaciones para envío'));
        } else {
            saveVerification(prodsToVerify);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Envío exitoso'));
        }
        customMsg = '22';        
        pageRef.setRedirect(false);
        return pageRef;
    }

    public PageReference redirectV() {
        System.debug('customMsg redm[' + customMsg + '] redirectV');
        PageReference pageRef = new PageReference('/apex/ConfirmacionOppCostVerification?res='+customMsg);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Envío exitoso'));
        pageRef.setRedirect(false);
        return pageRef;        
    }

    public PageReference manualVerification() {
    //public void manualVerification() {
        System.debug('Ver manual');
        PageReference pageRef = new PageReference('/apex/ConfirmacionOppCostVerification?res=1');
        prodsToVerify = new List<ProductCostVerification>();

        for(ProductCostVerification pcv : prods) {
            if(pcv.isMarkedForVerification) {
                System.debug('added');
                prodsToVerify.add(pcv);
            }
        }

        if(prodsToVerify.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'No hay verificaciones para envío'));
        } else {
            saveVerification(prodsToVerify);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Envío exitoso'));
        }
        customMsg = '11';
        System.debug('pageref xyy [' + pageRef + '] [' + customMsg + ']');        
        pageRef.setRedirect(false);
        return pageRef;
    }


    private void saveVerification(List<ProductCostVerification> pdsToVerify) {
        Verificacion_Costo__c vc;
        List<Verificacion_Costo_Productos__c> vcpList;
        Verificacion_Costo_Productos__c vcp;

        vc = new Verificacion_Costo__c(Name = originalOpportunity.Name,
                                       Estado__c = 'En Verificacion');
        
        insert vc;

        vcpList = new List<Verificacion_Costo_Productos__c>();

        for(ProductCostVerification pvc : pdsToVerify) {
            vcp = new Verificacion_Costo_Productos__c(Verificacion_Costo__c = vc.Id,
                                                      Opportunity__c = originalOpportunity.Id,
                                                      Factory__c  = pvc.idFactory,
                                                      Estado__c = 'Pendiente',
                                                      Fecha_Estado__c = Date.today(),
                                                      Product__c = pvc.product.Id);
            vcpList.add(vcp);                                        
        }

        insert vcpList;
    }


    public Map<String, String> getProductsInVerification() {
        List<Verificacion_Costo_Productos__c> verificaciones;

        mapVerificacionProductos = new Map<String, String>();

        verificaciones = [SELECT Id, 
                                 Name,
                                 Estado__c,
                                 Product__c
                            FROM Verificacion_Costo_Productos__c 
                           WHERE Estado__c 
                              IN ('Pendiente', 'Token Enviado', 'Verificado')];

        for(Verificacion_Costo_Productos__c vc : verificaciones) {
            mapVerificacionProductos.put(vc.Product__c, vc.Id);
        }

        return mapVerificacionProductos;
    }

}