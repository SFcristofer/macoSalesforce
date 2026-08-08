/**
*   Controller for the page of the same name. Calculates and presents business metrics for the current year.
*
*   @author lcosta@infolastic.com
*   @version 1.0
*/
public with sharing class BoardMeetingAgenda {
    public static final String SORIANA_NAME = 'SORIANA - GRUPO';
  public static final String ALL = 'ALL';
    public static final String REST = 'REST';
    
    public static final String CLOSED_WON = 'Cerrada/Ganada';

    private Account soriana;

    public Integer currentYear {get;set;}
    public Map<String, Decimal> yearsBudget {get;set;}
    public Map<String, Decimal> shareOfYearsBudget {get;set;}
    private Map<String, Decimal> targetedProfit;
    public Map<String, Decimal> targetedProfitMargin {get;set;}

    public Map<String, Decimal> closedOppsAmount {get;set;}
    private Map<String, Decimal> closedOppsProfit;
    public Map<String, Decimal> closedOppsMargin {get;set;}
    
    public Map<String, Decimal> pendingOppsAmount {get;set;}
    private Map<String, Decimal> pendingOppsProfit;
    public Map<String, Decimal> pendingOppsMargin {get;set;}

    public Map<String, Decimal> closedNPendingOppsAmount {get;set;}
    private Map<String, Decimal> closedNPendingOppsProfit;
    public Map<String, Decimal> closedNPendingOppsMargin {get;set;}

    public Map<String, Decimal> percentageOfTotalSale {get;set;}
    public Map<String, Decimal> salesOverBudget {get;set;}
    public Map<String, Decimal> closedOverProjectedMargin {get;set;}

    public BoardMeetingAgenda(ApexPages.StandardController std) {
        String strYear;
        currentYear = Date.Today().year();
        strYear = String.valueOf(currentYear);
        Ano_Reporte__mdt year = [SELECT Ano__c
                                FROM Ano_Reporte__mdt
                                LIMIT 1];
        if(year != null && year.Ano__c != null){
            currentYear = Integer.valueOf(year.Ano__c);
        }
        Date startDate = Date.newInstance(currentYear, 1, 1);
        Date endDate = Date.newInstance(currentYear, 12, 31);

        soriana = [SELECT Id
                    FROM Account
                    WHERE Name = :SORIANA_NAME];

        /******************************************************/
            /** Planning: Years budget & projected profit margin **/
            
        yearsBudget = new Map<String, Decimal>{ALL => 0, SORIANA_NAME => 0, REST => 0};
        targetedProfit = new Map<String, Decimal>{ALL => 0, SORIANA_NAME => 0, REST => 0};
        
        for(PlanificacionComercial__c p : [SELECT ObjetivoDeVentas__c,
                                                ObjetivoDeVentasNeto__c,
                                                Objetivo_de_Margen__c,
                                                Cuenta__r.Parent.ParentId,
                                                Cuenta__r.ParentId,
                                                Cuenta__r.CurrencyISOCode
                                                FROM PlanificacionComercial__c
                                                WHERE Activa__c = true
                                                AND Inicio__c >= :startDate
                                                AND Fin__c <= :endDate]){
            Decimal cRate = 1;
            yearsBudget.put(ALL, yearsBudget.get(ALL) + p.ObjetivoDeVentas__c / cRate);
            targetedProfit.put(ALL, targetedProfit.get(ALL) + (p.ObjetivoDeVentas__c * p.Objetivo_de_Margen__c) / cRate);
            if((p.Cuenta__r.ParentId != null && p.Cuenta__r.ParentId == soriana.Id) 
                    || (p.Cuenta__r.Parent.ParentId != null && p.Cuenta__r.Parent.ParentId == soriana.Id)){
                yearsBudget.put(SORIANA_NAME, yearsBudget.get(SORIANA_NAME) + p.ObjetivoDeVentas__c / cRate);
                targetedProfit.put(SORIANA_NAME, targetedProfit.get(SORIANA_NAME) + (p.ObjetivoDeVentas__c * p.Objetivo_de_Margen__c) / cRate);
            }else{
                yearsBudget.put(REST, yearsBudget.get(REST) + p.ObjetivoDeVentas__c / cRate);
                targetedProfit.put(REST, targetedProfit.get(REST) + (p.ObjetivoDeVentas__c * p.Objetivo_de_Margen__c) / cRate);
            }
        }

        Decimal base;
        shareOfYearsBudget = new Map<String, Decimal>();
        base = yearsBudget.get(ALL) == 0 ? 1 : yearsBudget.get(ALL);
        shareOfYearsBudget.put(SORIANA_NAME, Math.round(100 * (yearsBudget.get(SORIANA_NAME) / base)));
        shareOfYearsBudget.put(REST, Math.round(100 * (yearsBudget.get(REST) / base)));

        targetedProfitMargin = new Map<String, Decimal>();
        for(String key : yearsBudget.keySet()){
            base = yearsBudget.get(key) == 0 ? 1 : yearsBudget.get(key);
            targetedProfitMargin.put(key, (targetedProfit.get(key) / base).setScale(2));
        }
        
        /******************************************************/
        /** Actual: Current sales & obtained profit margin **/

        closedOppsAmount = new Map<String, Decimal>{ALL => 0, SORIANA_NAME => 0, REST => 0};
        closedOppsProfit = new Map<String, Decimal>{ALL => 0, SORIANA_NAME => 0, REST => 0};

        pendingOppsAmount = new Map<String, Decimal>{ALL => 0, SORIANA_NAME => 0, REST => 0};//TODO Define which are pending and calculate
        pendingOppsProfit = new Map<String, Decimal>{ALL => 0, SORIANA_NAME => 0, REST => 0};//TODO Define which are pending and calculate

        for(Opportunity o : [SELECT Id,
                                Account.Parent.ParentId,
                                Account.ParentId,
                                Costo_Estimado__c,
                                Importe_Neto2__c,
                                CurrencyISOCode
                                FROM Opportunity
                                WHERE PlanificacionComercial__r.Inicio__c >= :startDate
                                AND PlanificacionComercial__r.Fin__c <= :endDate
                                AND StageName = :CLOSED_WON]){

            Decimal cRate = CurrencyUtil.getRate(o.CurrencyIsoCode);
            if((o.Account.ParentId != null && o.Account.ParentId == soriana.Id) 
                    || (o.Account.Parent.ParentId != null && o.Account.Parent.ParentId == soriana.Id)){
                Decimal amount = o.Importe_Neto2__c / cRate;
                closedOppsAmount.put(SORIANA_NAME, closedOppsAmount.get(SORIANA_NAME) + amount);
                Decimal profit = (o.Importe_Neto2__c - o.Costo_Estimado__c) / cRate;
                closedOppsProfit.put(SORIANA_NAME, closedOppsProfit.get(SORIANA_NAME) + profit);
            }else{
                Decimal amount = o.Importe_Neto2__c / cRate;
                closedOppsAmount.put(REST, closedOppsAmount.get(REST) + amount);
                Decimal profit = (o.Importe_Neto2__c - o.Costo_Estimado__c) / cRate;
                closedOppsProfit.put(REST, closedOppsProfit.get(REST) + profit);
            }
            Decimal amount = o.Importe_Neto2__c / cRate;
            closedOppsAmount.put(ALL, closedOppsAmount.get(ALL) + amount);
            Decimal profit = (o.Importe_Neto2__c - o.Costo_Estimado__c) / cRate;
            closedOppsProfit.put(ALL, closedOppsProfit.get(ALL) + profit);

        }

        closedOppsMargin = new Map<String, Decimal>();
        for(String key : closedOppsProfit.keyset()){
            base = closedOppsAmount.get(key) == 0 ? 1 : closedOppsAmount.get(key);
            closedOppsMargin.put(key, (100 * closedOppsProfit.get(key) / base).setScale(2));
        }

        pendingOppsMargin = new Map<String, Decimal>{ALL => 0, SORIANA_NAME => 0, REST => 0};//TODO Define which are pending and calculate

        closedNPendingOppsAmount = new Map<String, Decimal>{ALL => 0, SORIANA_NAME => 0, REST => 0};
        closedNPendingOppsProfit = new Map<String, Decimal>{ALL => 0, SORIANA_NAME => 0, REST => 0};
        for(String key : closedOppsProfit.keyset()){
            closedNPendingOppsAmount.put(key, closedOppsAmount.get(key) + pendingOppsAmount.get(key));
            closedNPendingOppsProfit.put(key, closedOppsProfit.get(key) + pendingOppsProfit.get(key));
        }
        closedNPendingOppsMargin = new Map<String, Decimal>();
        for(String key : closedNPendingOppsAmount.keyset()){
            base = closedNPendingOppsAmount.get(key) == 0 ? 1 : closedNPendingOppsAmount.get(key);
            closedNPendingOppsMargin.put(key, (100 * closedNPendingOppsProfit.get(key) / base).setScale(2));
        }
        
        percentageOfTotalSale = new Map<String, Decimal>();
        base = closedNPendingOppsAmount.get(ALL) == 0 ? 1 : closedNPendingOppsAmount.get(ALL);
        percentageOfTotalSale.put(SORIANA_NAME, Math.round(100 * closedNPendingOppsAmount.get(SORIANA_NAME) / base));
        percentageOfTotalSale.put(REST, Math.round(100 * closedNPendingOppsAmount.get(REST) / base));

        salesOverBudget = new Map<String, Decimal>();
        for(String key : closedNPendingOppsAmount.keyset()){
            base = yearsBudget.get(key) == 0 ? 1 : yearsBudget.get(key);
            salesOverBudget.put(key, Math.round(100 * closedNPendingOppsAmount.get(key) / base));
        }

        closedOverProjectedMargin = new Map<String, Decimal>();
        base = targetedProfitMargin.get(ALL) == 0 ? 1 : targetedProfitMargin.get(ALL);
        closedOverProjectedMargin.put(ALL, (100 * closedNPendingOppsMargin.get(ALL) / base).setScale(2));
  }

    public String getALL(){
        return ALL;
    }

    public String getSORIANA(){
        return SORIANA_NAME;
    }

    public String getREST(){
        return REST;
    }
}