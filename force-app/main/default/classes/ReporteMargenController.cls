public class ReporteMargenController {
   public Date fechaIni;
   public Date fechaFin;
   public Date today;

   public List<PedidoDeCompra__c> pedidosTotales;
   public List<Opportunity> oppsCerradasGanadas;   
   public List<PlanificacionComercial__c> planificacionesTotales;   
   public Decimal costoTotalGeneral {set; get;}
   public Decimal importeVentaNetoGeneral {set; get;}
   public Decimal margenOperacionGeneral {set; get;}
   public Decimal objetivoVentasTotales {set; get;}
   public Decimal ventasTotales {set; get;}
   public Decimal cumplimientoTotal {set; get;}

   public Decimal margenOperacionesObjetivoGeneral {set; get;}  
   public Decimal margenObjetivoGeneral {set; get;}
   public Decimal objetivoVentaNetaGeneral {set; get;}
   public Decimal margenCumplimientoGeneral {set; get;}

   public Integer currentYear {set; get;}

   public String errorMsg {set; get;}

   public Integer anoReporte {set; get;}
   public boolean isExecutivePage {set; get;}
   public String opportunityOwnerId {set; get;}
   private static String PAGE_NAME_EXECUTIVE = 'ReporteMargenPorEjecutivo';
   private static String OPP_STAGE_NAME = 'Cerrada/Ganada';
   public String tstURL {set; get;}

   public ReporteMargenController() {
      String url;
      isExecutivePage = false;

      anoReporte = Date.Today().year();
      /*Ano_Reporte__mdt ano = [SELECT Ano__c
                              FROM Ano_Reporte__mdt
                              LIMIT 1];
      if(ano != null && ano.Ano__c != null){
          anoReporte = Integer.valueOf(ano.Ano__c);
      }*/
      fechaIni = Date.newInstance(anoReporte, 1, 1);
      fechaFin = Date.newInstance(anoReporte, 12, 31);

      System.debug('anioReporte[' + anoReporte + ']  fini[' + fechaIni + ']  ffin[' + fechaFin + ']');

      //today = Date.today();
      //fechaIni = Date.newInstance(today.year(),1,1);//ymd
      //fechaFin = Date.newInstance(today.year(),12,31);
      //currentYear = today.year();
      currentYear = anoReporte;

      url = Apexpages.currentPage().getUrl();
      tstURL = url;
      System.debug('URL [' + url + ']');
      if(url != null && url.contains(PAGE_NAME_EXECUTIVE)) {
          opportunityOwnerId = UserInfo.getUserId();
          isExecutivePage = true;
      }

      System.debug('isExec [' + isExecutivePage + ']  oppOwnerId[' + opportunityOwnerId + ']');
          
      oppsCerradasGanadas = getOportunidadesCerradasGanadas(fechaIni, fechaFin);
      planificacionesTotales = getPlanificacionesTotales(fechaIni, fechaFin);
      calcularMargenOp(oppsCerradasGanadas);
      calcularTotalesObjetivos(planificacionesTotales);
   }

   private List<PlanificacionComercial__c> getPlanificacionesTotales(Date fechaInicio, Date fechaFin) {
      List<PlanificacionComercial__c> planificaciones;

      String baseQuery = 'SELECT Id, ' +
                                'Name, ' +
                                'Activa__c, ' +
                                'Inicio__c, ' +
                                'Fin__c, ' +
                                'Cuenta__c, ' +
                                'Cuenta__r.Name, ' +
                                'ObjetivoDeVentas__c, ' +
                                'Ventas__c, ' + 
                                'ObjetivoDeVentasNeto__c, ' +
                                'CurrencyIsoCode, ' +
                                'Objetivo_de_Margen__c ' +
                           'FROM PlanificacionComercial__c ' +
                          'WHERE Activa__c = true ' +
                            'AND Inicio__c >= :fechaInicio ' +
                            'AND Fin__c <= :fechaFin';
      
      String ownerIdFilter = '  AND Cuenta__r.OwnerId = :opportunityOwnerId'; 

      if(isExecutivePage) {
         baseQuery = baseQuery + ownerIdFilter;
      }

      System.debug('baseQuery [' + baseQuery + ']');
      
      planificaciones = Database.query(baseQuery);

      return planificaciones;
   }
 

   private List<Opportunity> getOportunidadesCerradasGanadas(Date fechaInicio, Date fechaFin) {
      List<Opportunity> opps;

      String baseQuery = 'SELECT Id, ' +
                                'Name, ' +      
                                'PlanificacionComercial__c, ' +
                                'PlanificacionComercial__r.Inicio__c, ' +
                                'PlanificacionComercial__r.Fin__c, ' +
                                'StageName, ' +
                                'Costo_Estimado__c, ' +
                                'CurrencyIsoCode, ' +
                                'Importe_Neto2__c ' +
                           'FROM Opportunity ' +
                          'WHERE PlanificacionComercial__r.Inicio__c >= :fechaInicio ' +
                            'AND PlanificacionComercial__r.Fin__c <= :fechaFin ' +
                            'AND StageName = :OPP_STAGE_NAME';

      String ownerIdFilter = ' AND OwnerId = :opportunityOwnerId';

      if(isExecutivePage) {
         baseQuery = baseQuery + ownerIdFilter;
      }
      System.debug('baseQuery [' + baseQuery + ']');
      opps = Database.query(baseQuery);

      return opps;
   }

   public void calcularMargenOp(List<Opportunity> oppsCerradasGanadas) {
       Decimal cRate;
      costoTotalGeneral = 0;
      Decimal sumaMargeOpp = 0;
      Decimal sumaPriceOpp = 0;
      Decimal sumaImporteNeto = 0;
      Decimal sumaCostoEstimado = 0;

      System.debug('opps cerr gan.size[' + oppsCerradasGanadas.size() + ']');
      
      for(Opportunity opp : oppsCerradasGanadas) {
         cRate = CurrencyUtil.getRate(opp.CurrencyIsoCode);
         sumaImporteNeto = sumaImporteNeto + (opp.Importe_Neto2__c / cRate);
         sumaCostoEstimado = sumaCostoEstimado + (opp.Costo_Estimado__c / cRate);
         System.debug('id[' + opp.Id + '] name[' + opp.Name + '] imp Neto[' + opp.Importe_Neto2__c + ']  costo est[' + opp.Costo_Estimado__c + ']');
      }

      System.debug('sumaImporte Neto[' + sumaImporteNeto + ']  sumaCosto Estimado[' + sumaCostoEstimado + ']');
      
      if(sumaImporteNeto != 0) {
         margenOperacionGeneral = 100 * ((sumaImporteNeto - sumaCostoEstimado) / sumaImporteNeto);
      } else {
         margenOperacionGeneral = 0;
      }
      System.debug('margen[' + margenOperacionGeneral + ']');
   }

   public void calcularTotalesObjetivos(List<PlanificacionComercial__c> planificaciones) {
       Decimal cRate;
      Decimal objetivoProdMargen = 0;
      objetivoVentasTotales = 0;
      ventasTotales = 0;
      cumplimientoTotal = 0;
      margenOperacionesObjetivoGeneral = 0;
      margenObjetivoGeneral = 0;
      objetivoVentaNetaGeneral = 0;
      margenCumplimientoGeneral = 0;

      System.debug('planificaciones.size[' + planificaciones.size() + ']');

      for(PlanificacionComercial__c planificacion : planificaciones) {
         cRate = CurrencyUtil.getRate(planificacion.CurrencyIsoCode);
         objetivoVentasTotales = objetivoVentasTotales + (planificacion.ObjetivoDeVentas__c / cRate);
         ventasTotales = ventasTotales + planificacion.Ventas__c;
         objetivoVentaNetaGeneral = objetivoVentaNetaGeneral + (planificacion.ObjetivoDeVentasNeto__c / cRate);
         if(planificacion.Objetivo_de_Margen__c == null) {
            errorMsg = 'Objetivo de Margen en planificación [' + planificacion.Name + '] [' + planificacion.Id + '] debe tener valores asignados';
            return;
         }
         if(planificacion.ObjetivoDeVentasNeto__c == null) {
            errorMsg = 'Objetivo de Ventas Neto en planificación [' + planificacion.Name + '] [' + planificacion.Id + '] debe tener valores asignados';
            return;
         }
         objetivoProdMargen = objetivoProdMargen + ((planificacion.ObjetivoDeVentasNeto__c * planificacion.Objetivo_de_Margen__c) / cRate);
         
         System.debug('PL id[' + planificacion.Id + '] name[' + planificacion.Name + '] OBJ V neto[' + planificacion.ObjetivoDeVentasNeto__c + ']  obj margen[' + planificacion.Objetivo_de_Margen__c + ']');
      }

      System.debug('objetivoProdMargen[' + objetivoProdMargen + '] objetivoVentaNetaGeneral[' + objetivoVentaNetaGeneral + ']');

      if(objetivoVentaNetaGeneral != 0) {
          margenObjetivoGeneral = objetivoProdMargen / objetivoVentaNetaGeneral;
      } else {
         margenObjetivoGeneral = 0;
      }

      if(objetivoVentasTotales != 0) {
         cumplimientoTotal = 100 * (ventasTotales / objetivoVentasTotales);
      } else {
         cumplimientoTotal = 0;
      }
     
      System.debug('margenOperacionGeneral [' + margenOperacionGeneral + '] margenObjetivoGeneral[' + margenObjetivoGeneral + ']');     
     
      if(margenObjetivoGeneral != 0) {
         margenCumplimientoGeneral = 100 * (margenOperacionGeneral / margenObjetivoGeneral);
       } else {
         margenCumplimientoGeneral = 0;
       }
   }

}