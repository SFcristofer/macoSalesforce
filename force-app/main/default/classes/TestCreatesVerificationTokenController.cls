@isTest

private class TestCreatesVerificationTokenController {

    @isTest static void testTokenController() {
        Opportunity opportunity;
        Account fabrica;
        List<Verificacion_Costo_Productos__c> vcpList;
        Verificacion_Costo_Productos__c vcp;
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();
        fabrica = tu.getFabrica();
        opportunity = tu.getOpportunity();


        ApexPages.StandardController sc = new ApexPages.StandardController(opportunity);
        OppCostVerificationController  ocp = new OppCostVerificationController(sc);
        
        for(ProductCostVerification pcv : ocp.prods) {
            pcv.isMarkedForVerification = true;
        }
        
        ocp.manualVerification();

        vcpList = [SELECT Id, Name FROM Verificacion_Costo_Productos__c];
        if (!vcpList.isEmpty()) {
            vcp = vcpList.get(0);
            if(vcp != null) {
                ApexPages.currentPage().getParameters().put('idVcp', vcp.Id);
            }
        }
        
        ApexPages.currentPage().getParameters().put('id', fabrica.Id);

        CreatesVerificationTokenController tokenController = new CreatesVerificationTokenController();
        tokenController.generarTokenEnviar();
        String test = tokenController.comercialEmail;
        test = tokenController.providerName;

    }

}