public class ReporteAportaciones {
    private static final String TITLE = 'Aportaciones DO Brands - Cierre ';
    public List<ReporteAportacionesRow> aportacionesRows {set; get;}
    public String titulo {set; get;}

    public ReporteAportaciones() {
        List<String> parentIds;
        Map<String, Account> parentsMap;
        Date fechaIni = Date.today().addMonths(-1);
        aportacionesRows = loadAportaciones();
        titulo = TITLE + Util.getMonth(fechaIni.month()) + ' ' + fechaIni.year();
    }


    public List<ReporteAportacionesRow> loadAportaciones() {
        List<ReporteAportacionesRow> result = new List<ReporteAportacionesRow>();
        ReporteAportacionesRow row;
        for(Aportacion__c aportacion : [SELECT Id, 
                                            Name, 
                                            Numero_de_folio__c,
                                            Descripcion__c, 
                                            Fecha__c, 
                                            Importe__c, 
                                            CurrencyIsoCode,
                                            Planificacioncomercial__r.Name, 
                                            Planificacioncomercial__r.ObjetivoDeAportaciones__c,
                                            Planificacioncomercial__r.Cuenta__c,
                                            Planificacioncomercial__r.Cuenta__r.Sociedad__c,
                                            Planificacioncomercial__r.Cuenta__r.Name,
                                            Planificacioncomercial__r.Cuenta__r.ParentId,
                                            Planificacioncomercial__r.Cuenta__r.Parent.Name
                                            FROM Aportacion__c
                                            WHERE Estado__c = 'Lista'
                                            AND Enviada_Administracion__c = false]) {
            row = new ReporteAportacionesRow(aportacion.Id, aportacion);
            row.idTopParent = aportacion.Planificacioncomercial__r.Cuenta__r.ParentId;
            row.sociedad = aportacion.Planificacioncomercial__r.Cuenta__r.Sociedad__c;
            row.addParentAccount(aportacion.Planificacioncomercial__r.Cuenta__r.Parent);
            result.add(row);
        }
        return result;
    }
}