public class ProductExtensionController
{
    public static final String KEY_ACC = 'Key Account';

    public ApexPages.StandardSetController stdCon{get; set;}
    
    // List of products that we get with a query
    private List<Product2> productList;
    
    // Map of products selected with checkbox
    private Map<Id, Boolean> checkedProducts;
    
    // List of full products selected
    private Map<Id, Product2> selectedProducts; 
    
    public String prodSearch {get;set;}
    
    //flags to enable or disable output panel in UI
    public Boolean isEditEnabled {get;set;}
    public Boolean isSearchEnabled {get;set;}
    
    public String idSelectedProd {get;set;}
    
    public String selectedPricebook {get;set;}
    
    private List<OpportunityProductHybrid> hybridProds;
    
    private String opportunityId;
    
    private Opportunity opp;
    
    /*
     *  Initializes the page with a list of 300 products. This limit was applied to avoid viewstate error.
     *  The limit won't affect the operations, since sales executives use keyword search to find the products 
     *  and we don't apply the limit there.
     */
    public ProductExtensionController(ApexPages.StandardController controller) {
        opportunityId = controller.getId();

        opp = [SELECT Id, 
                      Pricebook2Id, 
                      PlanificacionComercial__r.PorcentajeAportaciones__c, 
                      PlanificacionComercial__r.PorcentajeConvenio__c,
                      CurrencyISOCode 
                 FROM Opportunity 
                WHERE Id = :opportunityId];
  
        selectedProducts = new Map<Id, Product2>();
        
        productList = [SELECT Id, 
                            Name,
                            Descripcion_Larga__c, 
                            Thumb1__c, 
                            CodigoDeProductoBase__c, 
                            ProductoBase__r.Marca__c, 
                            ProductoBase__r.unidadescontainer20__c, 
                            ProductoBase__r.unidadescontainer40__c, 
                            ProductoBase__r.unidadeshq__c, 
                            IsActive 
                            FROM Product2 
                            WHERE IsActive = true
                            AND Id IN (SELECT Product2Id FROM PricebookEntry WHERE CurrencyISOCode = :opp.CurrencyISOCode)
                            ORDER BY Descripcion_Larga__c
                            LIMIT 300];

        checkedProducts = new Map<Id, Boolean>();
        convertMapToList(productList, checkedProducts);
        
        stdCon = new ApexPages.StandardSetController(productList);
        stdCon.setPageSize(20);
        
        //KEY ACCOUNT PRICEBOOK MUST EXIST SO NOT CHECKING FOR NULLS HERE
        //NEEDS TO BE UPDATED ONCE WE ADD DIFF PRICEBOOKS FOR DIFF INCOTERMS
        List<Pricebook2> keyAccount = [SELECT Id, 
                                            Name 
                                            FROM Pricebook2
                                            WHERE Name = :KEY_ACC];
        
        isSearchEnabled = true;
        isEditEnabled = false;
        selectedPricebook = keyAccount[0].Id;
    }

    
    public List<Product2> getProductList()
    {
         List<Product2> lista;  
         if(stdCon != null)
         {
             System.debug('GET PL Standard Set Controller size[' + stdCon.getResultSize() + ']');
             lista = (List<Product2>)stdCon.getRecords();
             System.debug('GET PL Standard Set Controller size[' + lista.size() + ']');
             return (List<Product2>)stdCon.getRecords(); 
         }
         else
         {
             productList = new List<Product2>();
             return productList; 
         }
    }
 
    
    public void searchProducts()
    {
        String query, strFilter;

        if(prodSearch != null && (prodSearch).trim() !='')
        {
            strFilter = '((';
            Integer i = 0;
            for(String s : prodSearch.trim().split(' ')){
                if(i > 0){
                    strFilter += ' AND ';
                }
                strFilter += 'Descripcion_Larga__c Like \'%' + s + '%\'';
                i++;
            }
            strFilter += ') OR CodigoDeProductoBase__c Like \'%' + prodSearch.trim() + '%\')';
            
        }

        query = 'SELECT Id, Name, Descripcion_Larga__c, Thumb1__c, CodigoDeProductoBase__c, ProductoBase__r.Marca__c,'
                + ' ProductoBase__r.Unidadescontainer20__c, ProductoBase__r.unidadescontainer40__c,' 
                + ' ProductoBase__r.unidadeshq__c, IsActive FROM Product2 WHERE IsActive = true'
                + ' AND Id IN (SELECT Product2Id FROM PricebookEntry WHERE CurrencyISOCode = \'' + opp.CurrencyISOCode +'\')';
        
        if(strFilter != null)
        {
            query += ' AND ' + strFilter;
        }
        query += ' ORDER BY Descripcion_Larga__c LIMIT 300';

        system.debug('QUERY > ' + query + ' < ');
        productList = Database.query(query);
        convertMapToList(productList, checkedProducts);
        
        Product2 preSelected = null;
        for(Product2 pr : productList)
        {
            preSelected = selectedProducts.get(pr.id);
            if(preSelected != null)
            {
                checkedProducts.put(pr.id, true);
            }
        }
        
        stdCon = new ApexPages.StandardSetController(productList);            
        stdCon.setPageSize(20);
    }
    
    
    public Boolean hasNext 
    { 
        get 
        { 
            if(stdCon != null)
            {
                return stdCon.getHasNext(); 
            }
            return false;
            
        } 
        set; 
    } 

    public Boolean hasPrevious 
    { 
        get 
        { 
            if(stdCon != null)
            {
                return stdCon.getHasPrevious(); 
            }
            return false;
        } 
        set; 
    } 

    public Integer pageNumber 
    { 
        get 
        { 
            if(stdCon != null)
            {
               return stdCon.getPageNumber(); 
            }
            return 0;
        } 
        set; 
    } 

    public void previous() 
    { 
        if(stdCon != null)
        {
            stdCon.previous(); 
        }
    } 

    public void next() 
    { 
        if(stdCon != null)
        {
           stdCon.next(); 
        }
    } 
    
    public Integer getResultSize()
    {
        if(stdCon != null)
        {
           return stdCon.getResultSize();
        }
        return 0;
    }
    
 
    public Map<Id, Boolean> getCheckedProducts()
    {
        return checkedProducts;
    }  
    
    
    public void clickProduct()
    {
        Product2 prod;
        String param = Apexpages.currentPage().getParameters().get('idProd');
        Boolean value;
      
        String idp = param;
      
        value = checkedProducts.get(idp);
        if(value)
        {
            prod = findProductById(idp);
            if(prod != null)
            {
                selectedProducts.put(idp, prod);
            }
        }
        else
        {
            //if exist in selected products
            prod = selectedProducts.get(idp);
            if(prod != null)
            {
                //remove              
                selectedProducts.remove(idp);
            }
        }
    }
    
    public void clickDeleteSelectedProduct()
    {
        String prodId = null;
        //String[] tokens = null;
        Product2 prod;
        String param = Apexpages.currentPage().getParameters().get('idProdDel');
        if(idSelectedProd != null)
        {
            prodId = idSelectedProd;
                
            //if exist in selected products
            prod = selectedProducts.get(prodId);
            if(prod != null)
            {
                //remove      
                selectedProducts.remove(prodId);
            }
            checkedProducts.put(prodId, false);
        }
    }
    
    
    public Product2 findProductById(String id)
    {
        if(productList != null)
        {
          for(Product2 prod : productList)
          {
              if(prod.id.equals(id))
              {
                  return prod;
              }
          }
        }
        return null;
    }
    
    public List<Product2> getSelectedProducts()
    {
       List<Product2> listToDisplay = new List<Product2>();
       Product2 value = null;
       for(String idp : selectedProducts.keySet())
       {
           value = selectedProducts.get(idp);
           listToDisplay.add(value);
       }
       return listToDisplay;
    }
    

    public PageReference nextPage()
    {
        isSearchEnabled = false;
        isEditEnabled = true;        
        
        setupListHybridProducts();
        
        return null;
    }


    public PageReference previousPage()
    {
        isSearchEnabled = true;
        isEditEnabled = false;        
        return null;
    }

    
    /**
     * This method is used in UI in order to setup a map associated to checkboxes 
     */
    private void convertMapToList(List<Product2> listProducts, Map<Id, Boolean> checkedProducts)
    {
       for(Product2 p : productList)
       {
           checkedProducts.put(p.Id, false);
       }
    }
    
    
    /*
     * 
     */    
    public class OpportunityProductHybrid
    {
        public Opportunity oppHybridProd;
        public OpportunityLineItem item {get;set;}
        public Product2 product {get;set;}
        public Decimal priceWDisc {get;set;}
        
        public OpportunityProductHybrid(Id oppId, PricebookEntry pbe, Opportunity opp)
        {
            oppHybridProd = opp;
            
            item = new OpportunityLineItem(OpportunityId = oppId,
                                           PricebookEntryId = pbe.Id,
                                           Quantity = null,
                                           UnitPrice = calculateUnitPrice(pbe.UnitPrice).setScale(2),
                                           Aportaciones_2__c = oppHybridProd.PlanificacionComercial__r.PorcentajeAportaciones__c,
                                           Convenio_2__c = oppHybridProd.PlanificacionComercial__r.PorcentajeConvenio__c);
            priceWDisc = item.UnitPrice;
            product = pbe.Product2; 
        }
        
        
        /**
         * 
         */
        private Decimal calculateUnitPrice(Decimal unitPrice)
        {
           Decimal finalUnitPrice;
           finalUnitPrice = unitPrice / ( 1 - ((oppHybridProd.PlanificacionComercial__r.PorcentajeAportaciones__c + oppHybridProd.PlanificacionComercial__r.PorcentajeConvenio__c)/100));
           return finalUnitPrice;
        }
    }
    
    private void setupListHybridProducts()
    {
        List<PricebookEntry> listPriceBookEntry = null;
        List<String> idsProduct = new List<String>();
        Product2 prod;
        
        OpportunityProductHybrid hybridProd;

        for(String idp : selectedProducts.keySet())
        {
            idsProduct.add(idp);
        }

        listPriceBookEntry = [SELECT Id, 
                                     UnitPrice,
                                     Product2.Id,
                                     Product2.Name,
                                     Product2.Descripcion_Larga__c, 
                                     Product2.Thumb1__c, 
                                     Product2.CodigoDeProductoBase__c, 
                                     Product2.ProductoBase__r.Marca__c, 
                                     Product2.ProductoBase__r.Unidadescontainer20__c, 
                                     Product2.ProductoBase__r.Unidadescontainer40__c, 
                                     Product2.ProductoBase__r.Unidadeshq__c, 
                                     Product2.IsActive 
                                FROM PricebookEntry 
                               WHERE Pricebook2Id = :selectedPricebook 
                                 AND Product2Id IN :idsProduct
                                 AND CurrencyISOCode = :opp.CurrencyISOCode
                                 ORDER BY Product2.Descripcion_Larga__c];

        PriceBook2 priceBook = [SELECT Id, Name from Pricebook2 WHERE Id =:selectedPricebook ];
        
        hybridProds = new List<OpportunityProductHybrid>();
        
        for(PriceBookEntry pbe : listPriceBookEntry)
        {
            hybridProd = new OpportunityProductHybrid(opportunityId, pbe, opp);
            hybridProds.add(hybridProd );
        }
    }
    
    public List<OpportunityProductHybrid> getHybridProducts()
    {
        return hybridProds;
    }
    
    
    public void  saveOppLineItem()
    {
        if(opp.Pricebook2Id == null) {
            opp.Pricebook2Id = selectedPricebook;
            update opp;
        }
        String retUrl;    
        List<OpportunityLineItem> oppList = new List<OpportunityLineItem>();
        for(OpportunityProductHybrid hp : hybridProds)
        {
            if(hp.priceWDisc != hp.item.UnitPrice){
                hp.item.Modificar_precio_manual__c = true;
            }
            oppList.add(hp.item);
        }
        
        try
        {
            insert oppList;
        }
        catch(DmlException e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDMLMessage(0)));
        }
    }

    public Boolean hasError { 
        get { 
            return ApexPages.hasMessages();
        }       
    }
    
}