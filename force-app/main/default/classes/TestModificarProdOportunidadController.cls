@isTest
private class TestModificarProdOportunidadController {

    @isTest static void testModificarProdOportunidad() {
        String marcaValue;
        String marcaValueUpper;
        String familyValue;
        String familyValueUpper;
        
        String marcaProductoGarden;        
        String marcaProductoOutdoorSoriana;
        String familyProductoGarden;
        
        Schema.DescribeFieldResult fieldResult;
        List<Schema.PicklistEntry> ple;
    
        Opportunity opp;
        
        fieldResult = Product2.Marca__c.getDescribe();
        ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple) {
            marcaValue = pickListVal.getLabel();
            marcaValueUpper = marcaValue.toUpperCase();
            if(marcaValueUpper.contains('GARDEN')) {
                marcaProductoGarden = marcaValue;
            }
            if(marcaValueUpper.contains('OUTDOOR') && marcaValueUpper.contains('SORIANA')) {
                marcaProductoOutdoorSoriana = marcaValue;
            }
        }
        
        
        TestUtil tu = new TestUtil();
        tu.initOpportunityPedido();
        opp = tu.getOpportunity();
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        ModificarProductosOportunidadController mpController = new ModificarProductosOportunidadController(null);
        system.debug('LAU >> ' + mpController.oppLIWrapperList[1].brands);
        mpController.oppLIWrapperList[0].selectedBrand = marcaProductoGarden;
        mpController.oppLIWrapperList[1].selectedBrand = marcaProductoGarden;
        mpController.saveBrands();
    }

}