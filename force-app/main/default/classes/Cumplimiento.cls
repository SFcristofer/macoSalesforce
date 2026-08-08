public class Cumplimiento {
    public Integer anoReporte {set; get;}
    private Date fechaIni, fechaFin;
    private static String PAGE_NAME_EXECUTIVE = 'CumplimientoPorEjecutivo';
    private static String OPP_STAGE_NAME = 'Cerrada/Ganada';
    private boolean isExecutivePage;
    private String opportunityOwnerId;

    public Cumplimiento() {
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

        url = Apexpages.currentPage().getUrl();
        if(url != null && url.contains(PAGE_NAME_EXECUTIVE)) {
            opportunityOwnerId = UserInfo.getUserId();
            isExecutivePage = true;
        }

    }

    public Decimal getAvance() {
        String baseQuery = 'SELECT SUM(Importe_Neto2__c) s ' +
                             'FROM Opportunity ' +
                            'WHERE StageName = :OPP_STAGE_NAME ' +
                              'AND PlanificacionComercial__r.Inicio__c >= :fechaIni ' +
                              'AND PlanificacionComercial__r.Fin__c <= :fechaFin';
        String ownerIdFilter = ' AND OwnerId = :opportunityOwnerId';
        
        if(isExecutivePage) {
            baseQuery = baseQuery + ownerIdFilter;
        }
        AggregateResult vendido = Database.query(baseQuery);
        if(vendido.get('s') != null){
            return (Decimal)vendido.get('s');
        }
        return 0;
    }

    public Decimal getFalta(){
        Decimal diff = getObjetivo() - getAvance();
        if(diff > 0){
            return diff;
        }
        return 0;
    }

    private Decimal getObjetivo(){
        String strReportYear;
        strReportYear = String.valueOf(anoReporte);
        String baseQuery = 'SELECT SUM(ObjetivoDeVentas__c) o ' + 
                             'FROM PlanificacionComercial__c ' +
                            'WHERE Name = :strReportYear';

        String ownerIdFilter = ' AND Cuenta__r.OwnerId = :opportunityOwnerId';

        if(isExecutivePage) {
            baseQuery = baseQuery + ownerIdFilter;
        }

        AggregateResult objetivo = Database.query(baseQuery);

        if(objetivo.get('o') != null){
            return (Decimal)objetivo.get('o');
        }
        return 0;
    }
    
    public FormatedGoal getObjetivoFormated(){
        return new FormatedGoal(getObjetivo());
    }

    
    public class FormatedGoal{
        public String minifiedFig {get;set;}
        public String figLetter {get;set;}
        
        /**
        *    Given a Decimal d, represents it with its 2-3 most significant digits and a letter
        *    K for Thousands and M for Millions
        */
        public FormatedGoal(Decimal d){
            Integer i;
            Decimal toround, rounded;
            if(d > 999999){
                i = Integer.valueOf(d / 1000000);
                minifiedFig = String.valueOf(i);
                figLetter = 'M';
                if(d < 100000000){
                    toround = d / 1000000;
                    rounded = toround.setScale(1);
                    minifiedFig = String.valueOf(rounded).replace('.', ',');
                }
            }else{
                i = Integer.valueOf(d / 1000);
                minifiedFig = String.valueOf(i);
                figLetter = 'K';
                if(d < 100000){
                    toround = d / 1000;
                    rounded = toround.setScale(1);
                    minifiedFig = String.valueOf(rounded).replace('.', ',');
                }
            }
        }
        
    }
}