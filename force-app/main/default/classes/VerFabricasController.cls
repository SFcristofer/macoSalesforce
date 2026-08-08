public class VerFabricasController {
    public String idBaseProduct {set; get;}
    public String idFactory {set; get;}
    public String message {set; get;}
    public String descriptionProduct {set; get;}
    public List<FabricaAlternaCostos> fabricasAlternas {set; get;}

    public VerFabricasController() {
        idBaseProduct = ApexPages.CurrentPage().getparameters().get('idBaseProduct');
        idFactory = ApexPages.CurrentPage().getparameters().get('idFact');
        message = '';
        System.debug('idBaseProduct [' + idBaseProduct + ']  idFact [' + idFactory + ']');
        loadFabricas();
    }

    private void loadFabricas() {
        List<Product2> fabricasAlternasSOQL;       
        Map<String, FabricaAlternaCostos> fabricas = new Map<String, FabricaAlternaCostos>();
        FabricaAlternaCostos fabricaAlterna;

        List<Verificacion_Costo_Productos__c> listVCP;
        Verificacion_Costo_Productos__c vcp;        

        fabricasAlternas = new List<FabricaAlternaCostos>();

        fabricasAlternasSOQL = [SELECT Id, 
                                   Name, 
                                   Fabrica__c, 
                                   Fabrica__r.Name, 
                                   PrecioDeFabrica__c, 
                                   ProductoBase__c,
                                   ProductoBase__r.Descripcion_Larga__c 
                              FROM Product2
                             WHERE ProductoBase__c = :idBaseProduct];

        if(fabricasAlternasSOQL.size() == 1) {
            message = 'No hay fábricas alternas';
            if(fabricasAlternasSOQL.get(0).ProductoBase__r != null) {
                descriptionProduct = fabricasAlternasSOQL.get(0).ProductoBase__r.Descripcion_Larga__c;
            } else {
                descriptionProduct = '';
            }
        }

        listVCP = [SELECT Id, 
                          Factory__c,
                          Product__c,
                          New_Price__c 
                     FROM Verificacion_Costo_Productos__c
                    WHERE Factory__c = :idFactory
                      AND Product__r.ProductoBase__c = :idBaseProduct];

        if(!listVCP.isEmpty()) {
            vcp = listVCP.get(0);
        }                      

        for(product2 p : fabricasAlternasSOQL) {
            fabricaAlterna = new FabricaAlternaCostos();
            fabricaAlterna.idFabrica = p.fabrica__c;
            fabricaAlterna.name = p.Fabrica__r.Name;
            if(vcp != null) {
                if(vcp.New_Price__c == null) {
                    fabricaAlterna.newPrice = 'N/A';
                } else {
                    fabricaAlterna.newPrice = String.valueOf(vcp.New_Price__c);
                }
            } else {
                fabricaAlterna.newPrice = 'N/A';                
            }
            if(p.PrecioDeFabrica__c == null) {
                fabricaAlterna.currentPrice = 'N/A';
            } else {
                fabricaAlterna.currentPrice = String.valueOf(p.PrecioDeFabrica__c);
            }
            if(fabricaAlterna.idFabrica.equals(idFactory)) {
                fabricaAlterna.type = 'Principal';
            } else {
                fabricaAlterna.type = 'Alterna';
            }

            fabricas.put(p.Fabrica__c, fabricaAlterna);
        }

        for(String k : fabricas.keySet()) {
            fabricaAlterna = fabricas.get(k);
            fabricasAlternas.add(fabricaAlterna);
        }

    }


}