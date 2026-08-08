@isTest
private class TestCreatesProviderTokenController {

    @isTest static void testTokenController() {
        Account fabrica;
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();
        fabrica = tu.getFabrica();

        ApexPages.currentPage().getParameters().put('id', fabrica.Id);
        CreatesProviderTokenController tokenController = new CreatesProviderTokenController(null);
        tokenController.generarTokenEnviar();
        String test = tokenController.comercialEmail;
        test = tokenController.providerName;

    }

}