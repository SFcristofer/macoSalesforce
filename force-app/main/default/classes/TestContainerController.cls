@isTest
private class TestContainerController {

    @isTest static void testContainerController() {
        Container__c cntr;
        List<Container__c> cntrs;        
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();

        ContainerController.FileInput finput = new ContainerController.FileInput();
        finput.fileName = 'testFile.tst';
        finput.fileBody = Blob.valueOf('Test blob');
        
        ContainerController ctrlr = new ContainerController(new ApexPages.StandardController(tu.pedido1));
        ctrlr.saveContainer();
        cntrs = [SELECT Id, Name, Fecha_Carga_Contenedor__c from Container__c];
        if(cntrs != null && cntrs.size() > 0) {
            cntr = cntrs.get(0);
            ctrlr.container = cntr;
            System.debug('cntr id [' + cntr.Id + ']');
            
            ctrlr.cpLineItems = new List<ContainerPedidoLineItem>();

            ctrlr.saveItems();
            
            ctrlr.saveOrder();
            ctrlr.saveOrderC();
            ctrlr.cancelCntnrs();
            ctrlr.cancelCntnrItems();
            
            ctrlr.loadContainer(tu.pedido1.Id, cntr.Id);
            ctrlr.loadPedidoLineItems(tu.pedido1.Id);
            
            ctrlr.uploadFile(finput, tu.pedido1.Id, cntr.Id, 'Producción', 'Informe Carga de Contenedor');
            
            ApexPages.currentPage().getParameters().put('idContainer', cntr.Id);
            ctrlr.deleteContainer();
        } else {
            System.debug('Not saved cntr');
        }
        
    }
    
    @isTest static void testContainerControllerParam() {
        ContainerController ctrlr = new ContainerController();
        ContainerController.ContainerLineItem cli = new ContainerController.ContainerLineItem();
        cli.cantidadTotalItems = 0;
        cli.cantidadTotalItems = 0;
        cli.cantidadTotalCajas = 0;
        cli.cantidadCajasCntr = 0;
        cli.netWeight = 0;
        cli.grossWeight = 0;
        cli.cbm = 0;
    }    
    
/*    


        ContainerAddItems cai = new ContainerAddItems(new ApexPages.StandardController(tu.getProforma()));


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
    }*/

}