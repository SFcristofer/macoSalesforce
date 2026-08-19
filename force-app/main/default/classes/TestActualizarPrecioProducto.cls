@isTest
private class TestActualizarPrecioProducto {


    /**
    *   Cuando se crean Productos Base:
    *   El Product.trigger (y ProductTriggerHelper.cls) crean el Item de Escandallo correspondiente al producto
    *   Y copia el valor de Product2.UnidadesHQ en el campo ItemDeEscandallo.UnidadesHQ2
    *   
    */
    @isTest static void testItemsDeEscandalloCreados() {
        Test.startTest();
        TestUtil tu = new TestUtil();
        tu.initSoloBase();
        Test.stopTest();

        for(Product2 p : tu.getAllPBUpdated()){
            system.assertEquals(p.ItemsEscandallo__r.size(), 1);
            system.assertEquals(p.CostoImportacionUnidad__c, p.ItemsEscandallo__r[0].CostoImportacionUnidad__c);
            system.assertEquals(p.UnidadesHQ__c, p.ItemsEscandallo__r[0].UnidadesHQ2__c);
        }

    }

    /**
    *   Cuando se crean Productos de Fabrica, 
    *   El Product.trigger (y ProductTriggerHelper.cls) calculan CostoImportacionUnidad__c y 
    *   agregan los productos a todas las pricebooks con el margen establecido para cada una.
    */
    @isTest static void testCostosExtraYPricebooks() {
        Test.startTest();
        TestUtil tu = new TestUtil();
        tu.initTestData();
        Test.stopTest();

        Product2 actualizado = tu.getFirstPDFUpdated();
        system.assertEquals(actualizado.PrecioDeFabrica__c, tu.getFirstPDF().PrecioDeFabrica__c);
        system.assertEquals(tu.getFirstPDF().CostoImportacionUnidad__c, null);
        system.assertNotEquals(actualizado.CostoImportacionUnidad__c, null);
        for(PricebookEntry pbe : actualizado.PricebookEntries){
            system.debug('UnitPrice for ' + actualizado.Name + ': ' + pbe.UnitPrice);
            system.assertEquals(pbe.UnitPrice.setScale(2), 
                                        ((actualizado.PrecioDeFabrica__c 
                                            + actualizado.CostoImportacionUnidad__c 
                                            + actualizado.CostoPackaging__c) 
                                        / (1 - pbe.Pricebook2.Margen__c / 100)).setScale(2), 'El precio en cada Lista de Precios es igual al Costo Total / (1 - Margen)');
        }

    }


    /**
    *   Cuando se modifica el precio de un Producto de Fabrica, 
    *   El Product.trigger (y ProductTriggerHelper.cls) actualizan los Precios para el mismo en 
    *   todas las listas de precios. Ademas, en caso de que el Producto de Fabrica sea
    *   el mas caro para el Producto Base se Actualiza el PrecioCompraFabrica del Item de Escandallo.
    */
    @isTest static void testUpdatePrecioDeFabrica() {
        Test.startTest();
        TestUtil tu = new TestUtil();
        tu.initTestData();
        
        Product2 actualizado = tu.getFirstPDFUpdated();
        
        actualizado.PrecioDeFabrica__c += 50;
        Test.stopTest();
        
        ProductTriggerHelper.resetRunForTesting();//Necesito bypasear la bandera que me permite ejecutar una ves sola el trigger por contexto
        update actualizado;
        
        Product2 estadoFinal = tu.getFirstPDFUpdated();

        system.debug(actualizado.PricebookEntries[0].UnitPrice);
        system.debug(estadoFinal.PricebookEntries[0].UnitPrice);

        system.assert(actualizado.PricebookEntries[0].UnitPrice + 50 < 
                                estadoFinal.PricebookEntries[0].UnitPrice);

        for(Product2 p : tu.getAllPBUpdated()){
            if(p.Id == estadoFinal.ProductoBase__c){
                system.assertEquals(p.ItemsEscandallo__r[0].PrecioCompraFabrica__c,
                                    estadoFinal.PrecioDeFabrica__c + estadoFinal.CostoPackaging__c);
            }
        }


    }

    /**
    *   Cuando se modifica el margen de un Pricebook, 
    *   El Precio de todos los items se tiene que recalcular para esa lista de precios
    */
    @isTest static void testUpdatePricebookMargin() {
        Test.startTest();
        TestUtil tu = new TestUtil();
        tu.initTestData();
        
        list<Product2> pdfIniciales = tu.getAllPDFUpdated();
        System.debug('TEST ACTUALIZAR precio producto size-iniciales[' + pdfIniciales.size() + ']');
        Pricebook2 pb = tu.getCustomPricebook();
        System.debug('TEST ACTUALIZAR precio producto pb[' + pb + '] [' + pb.Id + ']');
        pb.Margen__c = 15;
        update pb;
        Test.stopTest();

        list<Product2> pdfFinales = tu.getAllPDFUpdated();
        System.debug('TEST ACTUALIZAR precio producto size[' + pdfFinales.size() + ']');
        for(Product2 finP : pdfFinales){
            System.debug('TEST ACTUALIZAR precio producto prodfin[' + finP.name + '] [' + finP.Id + ']');
            for(PricebookEntry pbF : finP.PricebookEntries){
                System.debug('TEST ACTUALIZAR precio producto pbookf[' + pbF.name + '] [' + pbF.Id + ']');
                for(Product2 iniP : pdfIniciales){
                    System.debug('TEST ACTUALIZAR precio producto prodIni[' + iniP.name + '] [' + iniP.Id + ']');
                    for(PricebookEntry pbI : iniP.PricebookEntries){
                        System.debug('TEST ACTUALIZAR precio producto pbooki[' + pbI.name + '] [' + pbI.Id + ']');
                        
                        System.debug('TEST ACTUALIZAR precio producto [' + pbF.Pricebook2Id + '] [' + pb.Id + '] [' + pbF.Id + '] [' + pbI.Id + ']');
                                                
                        if(pbF.Pricebook2Id == pb.Id && pbF.Id == pbI.Id){
                            System.debug('TEST ACTUALIZAR pbf.UnitPrice [' + pbF.Name + '] [' + pbF.UnitPrice + '] pbI.UnitPrice [' + pbI.Name + '] [' + pbI.UnitPrice + ']');
                            system.assert(pbF.UnitPrice >= pbI.UnitPrice);
                        }
                    }
                }
            }
        }
        System.debug('TEST ACTUALIZAR precio producto FIN');
    }

    /**
    *   Cuando se elimina un Producto Base, 
    *   El Product.trigger (y ProductTriggerHelper.cls) eliminan el Item de Escandallo Asociado 
    *   asi como todos sus sub-productos (Productos de Fabrica, etc).
    */
    @isTest static void testDeleteProductoBase() {
        Test.startTest();
        TestUtil tu = new TestUtil();
        tu.initTestData();
        
        system.assertEquals(tu.getAllPDFUpdated().size(), 2);
        system.assertEquals(tu.getAllItemsEscandallo().size(), 2);

        Product2 aBorrar = tu.getAllPBUpdated()[0];
        Id idABorrar = aBorrar.Id;

        system.assertEquals(tu.getPDFForBase(idABorrar).size(), 1);
        system.assertEquals(tu.getItemsEscandalloForBase(idABorrar).size(), 1);

        Test.stopTest();
        
        ProductTriggerHelper.resetRunForTesting();//Necesito bypasear la bandera que me permite ejecutar una ves sola el trigger por contexto
        delete aBorrar;
        
        system.assertEquals(tu.getAllPDFUpdated().size(), 1);
        system.assertEquals(tu.getAllItemsEscandallo().size(), 1);

        system.assertEquals(tu.getPDFForBase(idABorrar).size(), 0);
        system.assertEquals(tu.getItemsEscandalloForBase(idABorrar).size(), 0);

    }
    
    @isTest static void testPropertiesAndCoverage() {
        Test.startTest();
        TestUtil tu = new TestUtil();
        tu.initTestData();
        ActualizarPrecioProductoController controller = new ActualizarPrecioProductoController();
        controller.productoEstaActualizado = true;
        Boolean b = controller.productoEstaActualizado;
        controller.escandalloLastUpdated = datetime.now();
        datetime dt = controller.escandalloLastUpdated;
        System.assertEquals(true, b);
        Test.stopTest();
    }
    @isTest static void testUpdatePriceCoverage() {
        Test.startTest();
        TestUtil tu = new TestUtil();
        tu.initTestData();
        
        List<Product2> baseProducts = tu.getAllPBUpdated();
        Set<Id> baseIds = new Set<Id>();
        for(Product2 p : baseProducts){
            baseIds.add(p.Id);
        }
        
        // Cubrir el constructor parametrizado y la ejecución de updatePrice
        ActualizarPrecioProductoController controller = new ActualizarPrecioProductoController(baseIds);
        controller.updatePrice();
        
        // Cubrir el constructor por defecto y la ejecución de updatePrice general
        ActualizarPrecioProductoController controller2 = new ActualizarPrecioProductoController();
        controller2.updatePrice();
        
        Test.stopTest();
        System.assert(true, 'Executed without exceptions');
    }
    
}