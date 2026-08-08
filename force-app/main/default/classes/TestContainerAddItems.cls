@isTest
private class TestContainerAddItems {
    
    @isTest static void testShowingItems() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        ContainerAddItems cai = new ContainerAddItems(new ApexPages.StandardController(tu.getProforma()));
    }
    
    @isTest static void testAddingItems() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        test.startTest();
        ContainerAddItems cai = new ContainerAddItems(new ApexPages.StandardController(tu.getProforma()));
        cai.containerItems[1].selected = true;
        cai.containerItems[1].numBoxes = 20;
        cai.save();
        test.stopTest();
    }

    @isTest static void testVolumeExceeded() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        ContainerAddItems cai = new ContainerAddItems(new ApexPages.StandardController(tu.getProforma()));
        Integer selectLarge = 0;
        if(cai.containerItems[0].oli.Product2.MasterboxM3_2__c != 1){
            selectLarge = 1;
        }
        cai.containerItems[selectLarge].selected = true;
        cai.containerItems[selectLarge].numBoxes = 50;
        cai.save();
        
        system.assertEquals(ApexPages.getMessages()[1].getSummary(), 
                            'El CBM para los items seleccionados (50.0CBM), supera el maximo para tipo de contenedor 20 pies(30.0CBM).');
    }

    @isTest static void testItemsAlreadyAdded() {
        TestUtil tu = new TestUtil();
        tu.initOpportunityTest();
        test.startTest();
        ContainerAddItems cai = new ContainerAddItems(new ApexPages.StandardController(tu.getProforma()));
        cai.containerItems[0].selected = true;
        cai.containerItems[0].numBoxes = 20;
        cai.save();
        test.stopTest();
        //Inicializo la controladora nuevamnete ya con un item agregado
        cai = new ContainerAddItems(new ApexPages.StandardController(tu.getProforma()));
    }
    
}