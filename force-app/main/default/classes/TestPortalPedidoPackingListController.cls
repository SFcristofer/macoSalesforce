@isTest
private class TestPortalPedidoPackingListController {
    @isTest static void testPortalProveedorAltaStandard() {
        String currentYear = String.valueOf(Date.Today().year());
        currentYear = currentYear.substring(2, currentYear.length());
        System.debug('TESTING STD');
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();

        ApexPages.currentPage().getParameters().put('orderName', 'PD' + currentYear + '001');
        
        PortalPedidoPackingListController pptc1 = new PortalPedidoPackingListController();
        pptc1.loadPage();

        ApexPages.currentPage().getParameters().put('orderName', 'PD' + currentYear + '001');

        PortalPedidoPackingListController pptc = new PortalPedidoPackingListController();
        pptc.loadPage();
        //pptc.savePL();
    }

   
    @isTest static void testPortalProveedorAltaGuest() {
        System.debug('TESTING GST');
        String currentYear = String.valueOf(Date.Today().year());
        currentYear = currentYear.substring(2, currentYear.length());
        List<Apexpages.Message> msgs;
        Boolean invalidTokenTest = false;
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();
        User u = [SELECT Id, Name, UserType FROM User limit 1];
        System.debug('U [' + u.Id + '] [' + u.Name + ']');

        System.runAs(u) {

            ApexPages.currentPage().getParameters().put('dbrToken', '123456');

            PortalPedidoPackingListController pptc1 = new PortalPedidoPackingListController();
            pptc1.loadPage();
            msgs = ApexPages.getMessages();
            for(Apexpages.Message msg:msgs) {
                System.debug('msg [' + msg + ']');
                if(msg.getDetail().contains('Invalid token') || msg.getDetail().contains('Token no válido')) {
                    invalidTokenTest = true;
                }
            }

            //System.assert(invalidTokenTest);

            ApexPages.currentPage().getParameters().put('dbrToken', '12345');
            ApexPages.currentPage().getParameters().put('orderName', 'PD' + currentYear + '001');

            PortalPedidoPackingListController pptc = new PortalPedidoPackingListController();
            pptc.loadPage();
        }
    }

}