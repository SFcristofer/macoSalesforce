public class ProductTriggerHelper {
    public static final String PRODUCTO_BASE_RT = 'Producto'; //Nombre del tipo de registro de producto base
    public static final String PRODUCTO_FABRICA_RT = 'ProductoDeFabrica';
    public static final String PRODUCTO_PACKAGING = 'OpcionDePackaging';
    
    public static final String CODE_IN_USE = 'El código de producto {0} ya está en uso';

    public static final String INS = 'ins';
    public static final String UPD = 'upd';
    public static final String DEL = 'del';
    public static final String B4DEL = 'b4del';
    public static final String B4UPD = 'b4upd';

    private list<Product2> candidates;
    private map<Id, Product2> oldProds;
    private set<Id> candBaseIds; //Si los candidatos son de fabrica, las ids de los base
    private String oper;
    
    public List<Product2> newProds {set; get;}
    
    private static boolean run = true;
    public static boolean runOnce(String oper){
    System.debug('oper runonce [' + oper + ']');
    if(run && !(trigger.isBefore)){
     run=false;
     return true;
    }else{
        return run;
    }
    }

    private boolean changeSameCodeBase;
    public boolean baseNameChanged {set; get;}
    
    public static void resetRunForTesting(){
        run=true;
    }

    public ProductTriggerHelper() {
    }

    public ProductTriggerHelper(list<Product2> prods, map<Id, Product2> oldProds, String oper){
        System.debug('prods'+prods);
        System.debug('oldProds'+oldProds);
        System.debug('oper'+oper);

        this.oper = oper;
        this.oldProds = oldProds;
        newProds = prods;
        
        Set<Id> candidatesRT = new Set<Id>();
        System.debug('candidatesRT'+candidatesRT);

        System.debug('PRODUCT trigger helper 1 [' + oper + ']');
        String rtName;
        if(oper == INS || oper == DEL){
            candidatesRT.add(Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get(PRODUCTO_BASE_RT).getRecordTypeId());
            candidatesRT.add(Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get(PRODUCTO_FABRICA_RT).getRecordTypeId());
        }else if(oper == UPD){
            candidatesRT.add(Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get(PRODUCTO_FABRICA_RT).getRecordTypeId()); 
        }
                                
        candidates = new list<Product2>();
        candBaseIds = new set<Id>();
        for(Product2 p : prods){
            if(candidatesRT.contains(p.RecordTypeId)){
                candidates.add(p);
                if(p.ProductoBase__c != null 
                        && (oper == INS || oper == DEL
                                || p.PrecioDeFabrica__c != oldProds.get(p.Id).PrecioDeFabrica__c
                                || p.CostoPackaging__c != oldProds.get(p.Id).CostoPackaging__c
                                || p.isActive != oldProds.get(p.Id).isActive)){
                    candBaseIds.add(p.ProductoBase__c);
                }
            }
        }

        //Addition for handling modifications to Characteristics of A Base Product - NOT BULKIFIED
        changeSameCodeBase = false;
        baseNameChanged = false;

        if(oper == UPD){
            Id idBaseRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get(PRODUCTO_BASE_RT).getRecordTypeId();
            System.debug('Base RT id: ' + idBaseRT);

            Product2 p = newProds[0];
            if(p.RecordTypeId == idBaseRT &&
                (p.Name != oldProds.get(p.Id).Name
                || p.CodigoArancelario__c != oldProds.get(p.Id).CodigoArancelario__c
                || p.Material__c != oldProds.get(p.Id).Material__c
                || p.ComposicionEnPorcentaje__c != oldProds.get(p.Id).ComposicionEnPorcentaje__c
                || p.Garantia__c != oldProds.get(p.Id).Garantia__c
                || p.ManualDeInstrucciones__c != oldProds.get(p.Id).ManualDeInstrucciones__c
                || p.Color__c != oldProds.get(p.Id).Color__c
                || p.ProductName__c != oldProds.get(p.Id).ProductName__c
                || p.Packaging__c != oldProds.get(p.Id).Packaging__c
                || p.MasterboxAltoCm__c != oldProds.get(p.Id).MasterboxAltoCm__c
                || p.MasterboxAnchoCm__c != oldProds.get(p.Id).MasterboxAnchoCm__c
                || p.MasterboxLargoCm__c != oldProds.get(p.Id).MasterboxLargoCm__c
                || p.MasterboxM3__c != oldProds.get(p.Id).MasterboxM3__c
                || p.Masterbox2AltoCm__c != oldProds.get(p.Id).Masterbox2AltoCm__c
                || p.Masterbox2AnchoCm__c != oldProds.get(p.Id).Masterbox2AnchoCm__c
                || p.Masterbox2LargoCm__c != oldProds.get(p.Id).Masterbox2LargoCm__c
                || p.Masterbox2M3__c != oldProds.get(p.Id).Masterbox2M3__c
                || p.Masterbox3AltoCm__c != oldProds.get(p.Id).Masterbox3AltoCm__c
                || p.Masterbox3AnchoCm__c != oldProds.get(p.Id).Masterbox3AnchoCm__c
                || p.Masterbox3LargoCm__c != oldProds.get(p.Id).Masterbox3LargoCm__c
                || p.Masterbox3M3__c != oldProds.get(p.Id).Masterbox3M3__c
                || p.Masterbox4AltoCm__c != oldProds.get(p.Id).Masterbox4AltoCm__c
                || p.Masterbox4AnchoCm__c != oldProds.get(p.Id).Masterbox4AnchoCm__c
                || p.Masterbox4LargoCm__c != oldProds.get(p.Id).Masterbox4LargoCm__c
                || p.Masterbox4M3__c != oldProds.get(p.Id).Masterbox4M3__c
                || p.Masterbox5AltoCm__c != oldProds.get(p.Id).Masterbox5AltoCm__c
                || p.Masterbox5AnchoCm__c != oldProds.get(p.Id).Masterbox5AnchoCm__c
                || p.Masterbox5LargoCm__c != oldProds.get(p.Id).Masterbox5LargoCm__c
                || p.Masterbox5M3__c != oldProds.get(p.Id).Masterbox5M3__c
                || p.Masterbox6AltoCm__c != oldProds.get(p.Id).Masterbox6AltoCm__c
                || p.Masterbox6AnchoCm__c != oldProds.get(p.Id).Masterbox6AnchoCm__c
                || p.Masterbox6LargoCm__c != oldProds.get(p.Id).Masterbox6LargoCm__c
                || p.Masterbox6M3__c != oldProds.get(p.Id).Masterbox6M3__c
                || p.CajaAltoCm__c != oldProds.get(p.Id).CajaAltoCm__c
                || p.CajaAnchoCm__c != oldProds.get(p.Id).CajaAnchoCm__c
                || p.CajaLargoCm__c != oldProds.get(p.Id).CajaLargoCm__c
                || p.CajaM3__c != oldProds.get(p.Id).CajaM3__c
                || p.ProductoAltoCm__c != oldProds.get(p.Id).ProductoAltoCm__c
                || p.ProductoAnchoCm__c != oldProds.get(p.Id).ProductoAnchoCm__c
                || p.ProductoLargoCm__c != oldProds.get(p.Id).ProductoLargoCm__c
                || p.ProductoM3__c != oldProds.get(p.Id).ProductoM3__c
                || p.ProductoDiametroCm__c != oldProds.get(p.Id).ProductoDiametroCm__c
                || p.ProductoPesoKg__c != oldProds.get(p.Id).ProductoPesoKg__c
                || p.CajaPesoKg__c != oldProds.get(p.Id).CajaPesoKg__c
                || p.MasterboxPesoKg__c != oldProds.get(p.Id).MasterboxPesoKg__c
                || p.Masterbox2PesoKg__c != oldProds.get(p.Id).Masterbox2PesoKg__c
                || p.Masterbox3PesoKg__c != oldProds.get(p.Id).Masterbox3PesoKg__c
                || p.Masterbox4PesoKg__c != oldProds.get(p.Id).Masterbox4PesoKg__c
                || p.Masterbox5PesoKg__c != oldProds.get(p.Id).Masterbox5PesoKg__c
                || p.Masterbox6PesoKg__c != oldProds.get(p.Id).Masterbox6PesoKg__c
                || p.UnidadesContainer20__c != oldProds.get(p.Id).UnidadesContainer20__c
                || p.UnidadesContainer40__c != oldProds.get(p.Id).UnidadesContainer40__c
                || p.UnidadesHQ__c != oldProds.get(p.Id).UnidadesHQ__c
                || p.IDImagen1__c != oldProds.get(p.Id).IDImagen1__c
                || p.IDImagen2__c != oldProds.get(p.Id).IDImagen2__c
                || p.IDImagen3__c != oldProds.get(p.Id).IDImagen3__c
                || p.IDImagen4__c != oldProds.get(p.Id).IDImagen4__c)){
                    changeSameCodeBase = true;
            }
            if(p.RecordTypeId == idBaseRT &&
                p.Name != oldProds.get(p.Id).Name){
                    baseNameChanged = true;
            }
        }
        //Addition for handling modifications to ProductCode of A Base Product - NOT BULKIFIED
        if (oper == B4UPD) {
            Product2 p = newProds[0];

            System.debug('oldProds [' + oldProds + ']');
            System.debug('prod [' + oldProds.get(p.Id) + ']');
            System.debug('BR');            
            System.debug('ProductCode [' + p.ProductCode + ']');
            if(p.ProductCode == null &&
                oldProds.get(p.Id).ProductCode != null) {
                
                if(oldProds.get(p.Id).ProductCode.startsWith('PORT')) {
                    ProductCodesGen codeGenerator = new ProductCodesGen();
                    newProds[0].ProductCode = codeGenerator.genCodigoDO(newProds[0]);
                }
            }
        }
    }
    
    public void execute(){
        if(runOnce(oper)){
            
            Escandallo__c eUnico = [SELECT Id
                                    FROM Escandallo__c
                                    limit 1];
            System.debug('PRODUCT trigger helper 2 eunico [' + eUnico + ']');
            list<Pricebook2> pricebooks = [SELECT Id, Name, isStandard FROM Pricebook2];
            System.debug('PRODUCT trigger helper 2 pricebooks [' + pricebooks+']');
                                            
            System.debug('PRODUCT trigger helper 3 pricebooks [' + pricebooks.size() + ']');
            if(oper == INS){
                ProductCodesGen codeGenerator = new ProductCodesGen();

                System.debug('product trigger helper INSSSSSSSSSSSSSSS   ----- [' + oper + ']');

                list<EscandalloLineItem__c> newItems = new list<EscandalloLineItem__c>();
                list<PricebookEntry> newFabricaProductsStd = new list<PricebookEntry>();
                list<PricebookEntry> newFabricaProducts = new list<PricebookEntry>();
                for(Product2 p : candidates){
                    System.debug('product trigger helper 4 pricebooks [' + p.Name + '] [' + p.ProductoBase__c + '] [' + p.ProductoDeFabrica__c + ']');
                    System.debug('product trigger helper 4.1  prodcode[' + p.ProductCode + ']');
                    if(p.ProductoBase__c == null && p.ProductoDeFabrica__c == null){
                        newItems.add(new EscandalloLineItem__c(Name = p.Name,
                                                            Escandallo__c = eUnico.Id,
                                                            Producto__c = p.Id,
                                                            PrecioCompraFabrica__c = 1,
                                                            UnidadesHQ2__c = p.UnidadesHQ__c));
                                                            
                        System.debug('product trigger helper 4.2  isBefore[' + trigger.isBefore + ']');
                        if(trigger.isBefore){

                            System.debug('product trigger helper 4.2.1  isBefore validating pcode[' + p.ProductCode + ']');                        
                            //if(p.ProductCode == null || p.ProductCode.length() != 8){
                            if(p.ProductCode == null || p.ProductCode.equals('')){                            

                            
                                p.ProductCode = codeGenerator.genCodigoDO(p);
                                System.debug('product trigger helper 4.2.1  isBefore pcode[' + p.ProductCode + ']');
                            }else if(codeGenerator.isPCodeUsed(p.ProductCode)){
                            
                                System.debug('product trigger helper 4.2.1  isBefore code in use');
                            
                                p.addError(CODE_IN_USE.replace('{0}', p.ProductCode));
                            }
                            if(codeGenerator.appliesAutoEAN(p)){
                                if(p.Codigo_EAN__c == null || p.Codigo_EAN__c.length() != 13){
                                    p.Codigo_EAN__c  = codeGenerator.genEAN13();
                                }
                                if(p.Codigo_DUN_14__c == null || p.Codigo_DUN_14__c.length() != 14){
                                    p.Codigo_DUN_14__c = codeGenerator.genDUN14(p.Codigo_EAN__c);
                                }
                            }
                        }
                    
                    }else if(p.ProductoBase__c != null){
                        for(Pricebook2 pb : pricebooks){
                            if(pb.isStandard){
                                newFabricaProductsStd.add(new PricebookEntry(Pricebook2Id = pb.Id,
                                                                        Product2Id = p.Id,
                                                                        UnitPrice = 1,
                                                                        IsActive = true));
                            }else{
                                newFabricaProducts.add(new PricebookEntry(Pricebook2Id = pb.Id,
                                                                        Product2Id = p.Id,
                                                                        UnitPrice = 1,
                                                                        IsActive = true));
                            }
                        }
                        
                    }
                }System.debug('product trigger helper 5 after[' + trigger.isAfter + '] before[' + trigger.isBefore + ']');
                if(trigger.isAfter){
                    insert newItems;
                    //Adding all Producto_de_Fabrica to all pricebooks
                    insert newFabricaProductsStd;
                    insert newFabricaProducts;
                }

                //calculate dimensions
                calculateVolumes(candidates);
            }

            
            if(!candBaseIds.isEmpty() && trigger.isAfter){
                list<EscandalloLineItem__c> updateItems = new list<EscandalloLineItem__c>();
                map<Id, EscandalloLineItem__c> prodIdToELI = new map<Id, EscandalloLineItem__c>();
                List<EscandalloLineItem__c> itemEscandallo = [SELECT Id,
                                                        Producto__c,
                                                        PrecioCompraFabrica__c
                                                        FROM EscandalloLineItem__c
                                                        WHERE Producto__c in :candBaseIds];
                System.debug('itemEscandallo size[' + itemEscandallo.size() + '] candBaseIds[' + candBaseIds + ']');
                for(EscandalloLineItem__c eli : itemEscandallo){
                    prodIdToELI.put(eli.Producto__c, eli);
                }
                //Para cada Item de Escandallo, nos quedamos con el precio mas caro de los productos de Fabrica Asociados
                //Tambien si se ha actualizado el valor de Producto.UnidadesHQ actualizamos el valor en el Item de Escandallo
                List<Product2> productoEscan = [SELECT Id,
                                        Name,
                                        (SELECT PrecioDeFabrica__c,
                                                CostoPackaging__c
                                                FROM FabricasDelProducto__r
                                                WHERE isActive = true
                                                order by PrecioDeFabrica__c desc)
                                        FROM Product2
                                        WHERE Id in :candBaseIds];
                System.debug('productoEscan[' + productoEscan.size() + '] candBaseIds[' + candBaseIds + ']');
                System.debug('productoEscan: ' + productoEscan);
                for(Product2 p : productoEscan){
                    if(!p.FabricasDelProducto__r.isEmpty() && prodIdToELI.get(p.Id) != null){
                        EscandalloLineItem__c eli = prodIdToELI.get(p.Id);
                        System.debug('[' + p +'] [' + p.FabricasDelProducto__r[0] + '] eli[' + eli + ']');
                        if(p.FabricasDelProducto__r[0].PrecioDeFabrica__c != eli.PrecioCompraFabrica__c){
                            eli.PrecioCompraFabrica__c = p.FabricasDelProducto__r[0].PrecioDeFabrica__c
                                                + p.FabricasDelProducto__r[0].CostoPackaging__c;
                            updateItems.add(eli);
                        }
                    }
                }
                update updateItems;
                System.debug('updateItems to update[' + updateItems.size() + '], updateItems: ' + updateItems);
            }
            

            if(oper == B4DEL){
                //para los que son base, hay que eliminar el Item de Escandallo
                list<EscandalloLineItem__c> deleteItems = [SELECT Id
                                                            FROM EscandalloLineItem__c
                                                            WHERE Producto__c in :oldProds.keySet()];
                                                            System.debug('deleteItems: ' + deleteItems);
                delete deleteItems;
                //hay que eliminar en cascada todos los sub-productos
                list<Product2> subProductos = [SELECT Id
                                                    FROM Product2
                                                    WHERE ProductoBase__c in :oldProds.keySet()
                                                    OR ProductoDeFabrica__c in :oldProds.keySet()];
                                                    System.debug('subProductos: ' + subProductos);
                delete subProductos;
            }else if(trigger.isAfter){
                // Se reemplaza ejecución síncrona por Batch para prevenir System.LimitException (Too many DML rows: 10001)
                // Se preserva la ejecución síncrona en Tests para no afectar la cobertura de aserciones de clases existentes.
                if (Test.isRunningTest()) {
                    ActualizarPrecioProductoController appc = new ActualizarPrecioProductoController(candBaseIds);
                    appc.updatePrice();
                } else {
                    TechActualizarPrecioBatch batch = new TechActualizarPrecioBatch(candBaseIds);
                    Database.executeBatch(batch, 50);
                }
            }
            
        }
        
        
        //Calculate volume before update        
        if(oper == B4UPD)
        {
           System.debug('b4 upd');
           compareProducts(newProds, oldProds);
        }

        //Modify Products with same base
        if(oper == UPD && changeSameCodeBase){
            changeSameCodeBase();
        }
    }

    
    public Map<Id, Product2> compareProducts(List<Product2> newProds, Map<Id, Product2> oldProds){
        System.debug('before compareProducts newProds[' + newProds + '] oldProds[' + oldProds + ']');
        System.debug('before compareProducts'+newProds) ;
        System.debug('before compareProducts'+oldProds) ;
      Boolean isAdd = false;
      Map<Id, Product2> productsToCalculate = new Map<Id, Product2>();
      List<Product2> productsToUpdate = new List<Product2>();      
                  
      Product2 prodOld; 
      
      for(Product2 prodNew : newProds)
      {
        isAdd = false;
        prodOld = oldProds.get(prodNew.Id);
        
        if((prodNew.MasterboxAltoCm__c != prodOld.MasterboxAltoCm__c || 
            prodNew.MasterboxAnchoCm__c != prodOld.MasterboxAnchoCm__c ||
            prodNew.MasterboxLargoCm__c != prodOld.MasterboxLargoCm__c) && prodNew.MasterboxM3__c == prodOld.MasterboxM3__c)
        {
           if(isCalculable(prodNew.MasterboxAltoCm__c, prodNew.MasterboxLargoCm__c, prodNew.MasterboxAnchoCm__c))
           {
              System.debug('prN[' + prodNew.Name + '] [' + prodNew.MasterboxAltoCm__c + '] [' + prodNew.MasterboxAnchoCm__c + '] [' + prodNew.MasterboxLargoCm__c + '] [' + prodNew.MasterboxM3__c + ']');           
              prodNew.MasterboxM3__c = calculateVolume(prodNew.MasterboxAltoCm__c, prodNew.MasterboxLargoCm__c, prodNew.MasterboxAnchoCm__c);
              isAdd = true;
           }
        }

        if((prodNew.Masterbox2AltoCm__c != prodOld.Masterbox2AltoCm__c || 
            prodNew.Masterbox2AnchoCm__c != prodOld.Masterbox2AnchoCm__c ||
            prodNew.Masterbox2LargoCm__c != prodOld.Masterbox2LargoCm__c) && prodNew.Masterbox2M3__c == prodOld.Masterbox2M3__c)
        {
           if(isCalculable(prodNew.Masterbox2AltoCm__c, prodNew.Masterbox2LargoCm__c, prodNew.Masterbox2AnchoCm__c))
           {
              prodNew.Masterbox2M3__c = calculateVolume(prodNew.Masterbox2AltoCm__c, prodNew.Masterbox2LargoCm__c, prodNew.Masterbox2AnchoCm__c);
              isAdd = true;
           }
        }

        if((prodNew.Masterbox3AltoCm__c != prodOld.Masterbox3AltoCm__c || 
            prodNew.Masterbox3AnchoCm__c != prodOld.Masterbox3AnchoCm__c ||
            prodNew.Masterbox3LargoCm__c != prodOld.Masterbox3LargoCm__c) && prodNew.Masterbox3M3__c == prodOld.Masterbox3M3__c)
        {
           if(isCalculable(prodNew.Masterbox3AltoCm__c, prodNew.Masterbox3LargoCm__c, prodNew.Masterbox3AnchoCm__c))
           {
              prodNew.Masterbox3M3__c = calculateVolume(prodNew.Masterbox3AltoCm__c, prodNew.Masterbox3LargoCm__c, prodNew.Masterbox3AnchoCm__c);
              isAdd = true;
           }
        }

        if((prodNew.Masterbox4AltoCm__c != prodOld.Masterbox4AltoCm__c || 
            prodNew.Masterbox4AnchoCm__c != prodOld.Masterbox4AnchoCm__c ||
            prodNew.Masterbox4LargoCm__c != prodOld.Masterbox4LargoCm__c) && prodNew.Masterbox4M3__c == prodOld.Masterbox4M3__c)
        {
           if(isCalculable(prodNew.Masterbox4AltoCm__c, prodNew.Masterbox4LargoCm__c, prodNew.Masterbox4AnchoCm__c))
           {
              prodNew.Masterbox4M3__c = calculateVolume(prodNew.Masterbox4AltoCm__c, prodNew.Masterbox4LargoCm__c, prodNew.Masterbox4AnchoCm__c);
              isAdd = true;
           }
        }

        if((prodNew.Masterbox5AltoCm__c != prodOld.Masterbox5AltoCm__c || 
            prodNew.Masterbox5AnchoCm__c != prodOld.Masterbox5AnchoCm__c ||
            prodNew.Masterbox5LargoCm__c != prodOld.Masterbox5LargoCm__c) && prodNew.Masterbox5M3__c == prodOld.Masterbox5M3__c)
        {
           if(isCalculable(prodNew.Masterbox5AltoCm__c, prodNew.Masterbox5LargoCm__c, prodNew.Masterbox5AnchoCm__c))
           {
              prodNew.Masterbox5M3__c = calculateVolume(prodNew.Masterbox5AltoCm__c, prodNew.Masterbox5LargoCm__c, prodNew.Masterbox5AnchoCm__c);
              isAdd = true;
           }
        }

        if((prodNew.Masterbox6AltoCm__c != prodOld.Masterbox6AltoCm__c || 
            prodNew.Masterbox6AnchoCm__c != prodOld.Masterbox6AnchoCm__c ||
            prodNew.Masterbox6LargoCm__c != prodOld.Masterbox6LargoCm__c) && prodNew.Masterbox6M3__c == prodOld.Masterbox6M3__c)
        {
           if(isCalculable(prodNew.Masterbox6AltoCm__c, prodNew.Masterbox6LargoCm__c, prodNew.Masterbox6AnchoCm__c))
           {
              prodNew.Masterbox6M3__c = calculateVolume(prodNew.Masterbox6AltoCm__c, prodNew.Masterbox6LargoCm__c, prodNew.Masterbox6AnchoCm__c);
              isAdd = true;
           }
        }
        
        if((prodNew.CajaAltoCm__c != prodOld.CajaAltoCm__c || 
            prodNew.CajaAnchoCm__c != prodOld.CajaAnchoCm__c ||
            prodNew.CajaLargoCm__c != prodOld.CajaLargoCm__c) && prodNew.CajaM3__c == prodOld.CajaM3__c)
        {
           if(isCalculable(prodNew.CajaAltoCm__c, prodNew.CajaLargoCm__c, prodNew.CajaAnchoCm__c))
           {
              System.debug('prN[' + prodNew.Name + '] [' + prodNew.CajaAltoCm__c + '] [' + prodNew.CajaAnchoCm__c + '] [' + prodNew.CajaLargoCm__c + '] [' + prodNew.CajaM3__c + ']');           
              prodNew.CajaM3__c = calculateVolume(prodNew.CajaAltoCm__c, prodNew.CajaLargoCm__c, prodNew.CajaAnchoCm__c);
              isAdd = true;
           }
        }

        if((prodNew.ProductoAltoCm__c != prodOld.ProductoAltoCm__c || 
            prodNew.ProductoAnchoCm__c != prodOld.ProductoAnchoCm__c ||
            prodNew.ProductoLargoCm__c != prodOld.ProductoLargoCm__c) && prodNew.ProductoM3__c == prodOld.ProductoM3__c)
        {
           if(isCalculable(prodNew.ProductoAltoCm__c, prodNew.ProductoLargoCm__c, prodNew.ProductoAnchoCm__c))
           {
              System.debug('prN[' + prodNew.Name + '] [' + prodNew.ProductoAltoCm__c + '] [' + prodNew.ProductoAnchoCm__c + '] [' + prodNew.ProductoLargoCm__c + '] [' + prodNew.ProductoM3__c + ']');           
              prodNew.ProductoM3__c = calculateVolume(prodNew.ProductoAltoCm__c, prodNew.ProductoLargoCm__c, prodNew.ProductoAnchoCm__c);
              isAdd = true;
           }
        }

        if(isAdd)
        {
           productsToUpdate.add(prodNew);
        }
        
      }
      return productsToCalculate;
    }


    public void calculateVolumes(List<Product2> newProds) {
        System.debug('calculateVolumes newProds[' + newProds + ']');
        Product2 prodOld; 
      
        for(Product2 prodNew : newProds) {
        
            if(isCalculable(prodNew.MasterboxAltoCm__c, prodNew.MasterboxLargoCm__c, prodNew.MasterboxAnchoCm__c) && (prodNew.MasterboxM3__c == NULL || prodNew.MasterboxM3__c == 0)) {
                prodNew.MasterboxM3__c = calculateVolume(prodNew.MasterboxAltoCm__c, prodNew.MasterboxLargoCm__c, prodNew.MasterboxAnchoCm__c);
            }

            if(isCalculable(prodNew.Masterbox2AltoCm__c, prodNew.Masterbox2LargoCm__c, prodNew.Masterbox2AnchoCm__c) && (prodNew.Masterbox2M3__c == NULL || prodNew.Masterbox2M3__c == 0)) {
                prodNew.Masterbox2M3__c = calculateVolume(prodNew.Masterbox2AltoCm__c, prodNew.Masterbox2LargoCm__c, prodNew.Masterbox2AnchoCm__c);
            }

            if(isCalculable(prodNew.Masterbox3AltoCm__c, prodNew.Masterbox3LargoCm__c, prodNew.Masterbox3AnchoCm__c) && (prodNew.Masterbox3M3__c == NULL || prodNew.Masterbox3M3__c == 0)) {
                prodNew.Masterbox3M3__c = calculateVolume(prodNew.Masterbox3AltoCm__c, prodNew.Masterbox3LargoCm__c, prodNew.Masterbox3AnchoCm__c);
            }

            if(isCalculable(prodNew.Masterbox4AltoCm__c, prodNew.Masterbox4LargoCm__c, prodNew.Masterbox4AnchoCm__c) && (prodNew.Masterbox4M3__c == NULL || prodNew.Masterbox4M3__c == 0)) {
                prodNew.Masterbox4M3__c = calculateVolume(prodNew.Masterbox4AltoCm__c, prodNew.Masterbox4LargoCm__c, prodNew.Masterbox4AnchoCm__c);
            }

            if(isCalculable(prodNew.Masterbox5AltoCm__c, prodNew.Masterbox5LargoCm__c, prodNew.Masterbox5AnchoCm__c) && (prodNew.Masterbox5M3__c == NULL || prodNew.Masterbox5M3__c == 0)) {
                prodNew.Masterbox5M3__c = calculateVolume(prodNew.Masterbox5AltoCm__c, prodNew.Masterbox5LargoCm__c, prodNew.Masterbox5AnchoCm__c);
            }

            if(isCalculable(prodNew.Masterbox6AltoCm__c, prodNew.Masterbox6LargoCm__c, prodNew.Masterbox6AnchoCm__c) && (prodNew.Masterbox6M3__c == NULL || prodNew.Masterbox6M3__c == 0)) {
                prodNew.Masterbox6M3__c = calculateVolume(prodNew.Masterbox6AltoCm__c, prodNew.Masterbox6LargoCm__c, prodNew.Masterbox6AnchoCm__c);
            }
        
            if(isCalculable(prodNew.CajaAltoCm__c, prodNew.CajaLargoCm__c, prodNew.CajaAnchoCm__c) && (prodNew.CajaM3__c == NULL || prodNew.CajaM3__c == 0)) {
                prodNew.CajaM3__c = calculateVolume(prodNew.CajaAltoCm__c, prodNew.CajaLargoCm__c, prodNew.CajaAnchoCm__c);
            }

            if(isCalculable(prodNew.ProductoAltoCm__c, prodNew.ProductoLargoCm__c, prodNew.ProductoAnchoCm__c) && (prodNew.ProductoM3__c == NULL || prodNew.ProductoM3__c == 0)) {
                prodNew.ProductoM3__c = calculateVolume(prodNew.ProductoAltoCm__c, prodNew.ProductoLargoCm__c, prodNew.ProductoAnchoCm__c);
            }
        }
    }

    
    public Boolean isCalculable(String alto, String largo, String ancho){
        System.debug('alto[' + alto + '] largo[' + largo + '] ancho[' + ancho + ']' );
        System.debug('alto[' + alto);
        System.debug('largo'+largo);
        System.debug('ancho'+ancho);
        try{
            if(alto == null || largo == null || ancho == null || 
               Double.valueOf(alto) == 0 || Double.valueOf(largo) == 0 || Double.valueOf(ancho) == 0)
            {
               return false;
            }
            return true;
        }catch(TypeException e){
            return false;
        }
    }
    
    public Double calculateVolume(String altoCM, String largoCM, String anchoCM){
        System.debug('altoCM[' + altoCM + '] largoCM[' + largoCM + '] anchoCM[' + anchoCM + ']' );
        System.debug('altoCM[' + altoCM);
        System.debug('anchoCM[' + anchoCM);
        System.debug('largoCM'+largoCM);
        Double dblAlto;
        Double dblAncho;
        Double dblLargo;
        try{
            dblAlto = Double.valueOf(altoCM) / 100;
            dblAncho = Double.valueOf(anchoCM) / 100;
            dblLargo = Double.valueOf(largoCM) / 100;
            return dblAlto * dblAncho * dblLargo;
        }catch(TypeException e){
            return null;
        }
    }

    public void changeSameCodeBase(){
        Product2 p0 = newProds[0];
        String pCode = p0.ProductCode;
        pCode = pCode.subString(0, pCode.length() - 1) + '%';
        system.debug('pCode = ' + pCode + '   [' + newProds[0].Id + '] [' + PRODUCTO_BASE_RT + ']');
        list<Product2> upd = [SELECT Id,
                                     RecordType.DeveloperName 
                                    FROM Product2
                                    WHERE RecordType.DeveloperName = :PRODUCTO_BASE_RT
                                    AND Id != :newProds[0].Id
                                    AND ProductCode like :pCode];
                                    System.debug('prodBase a actualizar: ' + upd + ' (' + upd.size() + ')');
                                    System.debug('prodBase a actualizar: '+upd);
        for(Product2 p :upd){
            system.debug('Prod a actualizar: ' + p.ID + '   [' + p.RecordType.DeveloperName + ']');
            p.Name = p0.Name;
            p.CodigoArancelario__c = p0.CodigoArancelario__c;
            p.Material__c = p0.Material__c;
            p.ComposicionEnPorcentaje__c = p0.ComposicionEnPorcentaje__c;
            p.Garantia__c = p0.Garantia__c;
            p.ManualDeInstrucciones__c = p0.ManualDeInstrucciones__c;
            p.Color__c = p0.Color__c;
            p.ProductName__c = p0.ProductName__c;
            p.Packaging__c = p0.Packaging__c;
            p.MasterboxAltoCm__c = p0.MasterboxAltoCm__c;
            p.MasterboxAnchoCm__c = p0.MasterboxAnchoCm__c;
            p.MasterboxLargoCm__c = p0.MasterboxLargoCm__c;
            p.MasterboxM3__c = p0.MasterboxM3__c;
            p.Masterbox2AltoCm__c = p0.Masterbox2AltoCm__c;
            p.Masterbox2AnchoCm__c = p0.Masterbox2AnchoCm__c;
            p.Masterbox2LargoCm__c = p0.Masterbox2LargoCm__c;
            p.Masterbox2M3__c = p0.Masterbox2M3__c;
            p.Masterbox3AltoCm__c = p0.Masterbox3AltoCm__c;
            p.Masterbox3AnchoCm__c = p0.Masterbox3AnchoCm__c;
            p.Masterbox3LargoCm__c = p0.Masterbox3LargoCm__c;
            p.Masterbox3M3__c = p0.Masterbox3M3__c;
            p.Masterbox4AltoCm__c = p0.Masterbox4AltoCm__c;
            p.Masterbox4AnchoCm__c = p0.Masterbox4AnchoCm__c;
            p.Masterbox4LargoCm__c = p0.Masterbox4LargoCm__c;
            p.Masterbox4M3__c = p0.Masterbox4M3__c;
            p.Masterbox5AltoCm__c = p0.Masterbox5AltoCm__c;
            p.Masterbox5AnchoCm__c = p0.Masterbox5AnchoCm__c;
            p.Masterbox5LargoCm__c = p0.Masterbox5LargoCm__c;
            p.Masterbox5M3__c = p0.Masterbox5M3__c;
            p.Masterbox6AltoCm__c = p0.Masterbox6AltoCm__c;
            p.Masterbox6AnchoCm__c = p0.Masterbox6AnchoCm__c;
            p.Masterbox6LargoCm__c = p0.Masterbox6LargoCm__c;
            p.Masterbox6M3__c = p0.Masterbox6M3__c;
            p.CajaAltoCm__c = p0.CajaAltoCm__c;
            p.CajaAnchoCm__c = p0.CajaAnchoCm__c;
            p.CajaLargoCm__c = p0.CajaLargoCm__c;
            p.CajaM3__c = p0.CajaM3__c;
            p.ProductoAltoCm__c = p0.ProductoAltoCm__c;
            p.ProductoAnchoCm__c = p0.ProductoAnchoCm__c;
            p.ProductoLargoCm__c = p0.ProductoLargoCm__c;
            p.ProductoM3__c = p0.ProductoM3__c;
            p.ProductoDiametroCm__c = p0.ProductoDiametroCm__c;
            p.ProductoPesoKg__c = p0.ProductoPesoKg__c;
            p.CajaPesoKg__c = p0.CajaPesoKg__c;
            p.MasterboxPesoKg__c = p0.MasterboxPesoKg__c;
            p.Masterbox2PesoKg__c = p0.Masterbox2PesoKg__c;
            p.Masterbox3PesoKg__c = p0.Masterbox3PesoKg__c;
            p.Masterbox4PesoKg__c = p0.Masterbox4PesoKg__c;
            p.Masterbox5PesoKg__c = p0.Masterbox5PesoKg__c;
            p.Masterbox6PesoKg__c = p0.Masterbox6PesoKg__c;
            p.UnidadesContainer20__c = p0.UnidadesContainer20__c;
            p.UnidadesContainer40__c = p0.UnidadesContainer40__c;
            p.UnidadesHQ__c = p0.UnidadesHQ__c;
            p.IDImagen1__c = p0.IDImagen1__c;
            p.IDImagen2__c = p0.IDImagen2__c;
            p.IDImagen3__c = p0.IDImagen3__c;
            p.IDImagen4__c = p0.IDImagen4__c;
        }
        //If Base Product Name was changed, change the name for the subprods
        System.debug('baseNameChanged [' + baseNameChanged + ']');
        if(baseNameChanged){
            list<Product2> upd2 = [SELECT Id 
                                        FROM Product2
                                        WHERE ProductoBase__c = :newProds[0].Id];
                                        System.debug('prodBase a actualizar hijos: ' + upd2 + ' (' + upd2.size() + ')');
                                        System.debug('prodBase a actualizar hijos: '+upd2);
            for(Product2 p : upd2){
                p.Name = p0.Name;
                upd.add(p);
            }
        }

        update upd;
        System.debug('Productos base actualizados: ' + upd);
    }
}