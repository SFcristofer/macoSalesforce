public class ClienteContactoMargen implements Comparable
{
	public String idCliente {set; get;}
	public String clave {set; get;}	
    public String name {set; get;}
    public String cliente {set; get;}
    public String comprador {set; get;}	
    public Account account {set; get;}
	public List<Opportunity> oportunidades;	
	public List<PlanificacionComercial__c> planificacionesComerciales;

	public Decimal costoTotalGeneral {set; get;}
	public Decimal importeVentaNetoGeneral {set; get;}
	public Decimal margenReal {set; get;}
	public Decimal objetivoVentaNeta {set; get;}
	public Decimal margenObjetivoNeta {set; get;}
	public Decimal objetivoProdMargen {set; get;}
	public Decimal objetivoVentaMargen {set; get;}	// objetivoVentaNeta * margenObjetivoNeta
	public Decimal desviacion {set; get;}
	public Decimal desviacionMargen {set; get;}		

	public ClienteContactoMargen(Account paccount) {
       account = paccount;
	   idCliente = account.Id;
	   name = account.Name;
	   clave = account.Id_Externo__c;
	   oportunidades = new List<Opportunity>();
	   planificacionesComerciales = new List<PlanificacionComercial__c>();
	   margenReal = 0;
	   costoTotalGeneral = 0;
	   importeVentaNetoGeneral = 0;
	   objetivoVentaNeta = 0;
	   margenObjetivoNeta = 0;
	   objetivoProdMargen = 0;
	   objetivoVentaMargen = 0;
	   desviacion = 0;
	   desviacionMargen = 0;
	}

    public void addOportunidad(Opportunity opp) {
        oportunidades.add(opp);
	}

    public void addPlanificacionComercial(PlanificacionComercial__c ppc) {
        planificacionesComerciales.add(ppc);
	}

	public void calcularDatos() {
		Decimal cRate;
		for(Opportunity opp : oportunidades)  {
            cRate = CurrencyUtil.getRate(opp.CurrencyIsoCode);
			System.debug('[' + opp.Id + '] [' + opp.Name + '] opp.ImporteNeto[' + opp.Importe_Neto2__c + '] opp.Costo_Estimado__c[' + opp.Costo_Estimado__c + ']');
			importeVentaNetoGeneral = importeVentaNetoGeneral + (opp.Importe_Neto2__c / cRate);
            costoTotalGeneral = costoTotalGeneral + (opp.Costo_Estimado__c / cRate);
		}
	    System.debug('Total ImporteNeto[' + importeVentaNetoGeneral + '] Total Costo_Estimado__c[' + costoTotalGeneral + ']');
        if(importeVentaNetoGeneral != 0) {
            margenReal = 100 * ((importeVentaNetoGeneral - costoTotalGeneral) / importeVentaNetoGeneral);
		}
	    System.debug('Total MARGEN REAL[' + margenReal + ']');
	}

	public void calculateTragetMargin() {
		Decimal cRate;
	    Integer sizeOppList;
		sizeOppList = planificacionesComerciales.size();
		if(sizeOppList > 0) {
            for(PlanificacionComercial__c planificacion : planificacionesComerciales) {
               cRate = CurrencyUtil.getRate(planificacion.CurrencyIsoCode);
			   if(planificacion.ObjetivoDeVentasNeto__c != null) {
			       objetivoVentaNeta = planificacion.ObjetivoDeVentasNeto__c;
				   margenObjetivoNeta = planificacion.Objetivo_de_Margen__c;

				   objetivoVentaMargen = objetivoVentaMargen + ((objetivoVentaNeta * margenObjetivoNeta) / cRate);
				   System.debug('objetivoVentaMargen [' + idCliente + '] [' + objetivoVentaMargen + '] [' + planificacion.Cuenta__r.Name + ']');
			   }
			}
		}
		if(objetivoVentaNeta != 0) {
		   desviacion = importeVentaNetoGeneral / objetivoVentaNeta;
		}
        if(margenObjetivoNeta != 0) {
		   desviacionMargen = margenReal / margenObjetivoNeta;
		}
	}

    public Integer compareTo(Object compareTo) {
		Integer result = 0;
		ClienteContactoMargen clienteCompare = (ClienteContactoMargen)compareTo;

        if(account.BillingCountry == null && clienteCompare.account.BillingCountry == null) {
            return 0;
		}
        if(account.BillingCountry != null && clienteCompare.account.BillingCountry == null) {
            return 1;
		}
        if(account.BillingCountry == null && clienteCompare.account.BillingCountry != null) {
            return -1;
		}

		if(account.BillingCountry.equals(clienteCompare.account.BillingCountry)) {
			if(cliente == null && clienteCompare.cliente == null) {
			   return 0;
			}
			if(cliente != null && clienteCompare.cliente == null) {
			   return 1;
			}
			if(cliente == null && clienteCompare.cliente != null) {
			   return -1;
			}

			if(cliente.equals(clienteCompare.cliente)) {
			   result = 0;
			}
			if(cliente > clienteCompare.cliente) {
			   result = 1;
			}
			if(cliente < clienteCompare.cliente) {
			   result = -1;
			}
		}
		if(account.BillingCountry > clienteCompare.account.BillingCountry) {
		   result = 1;
		}
		if(account.BillingCountry < clienteCompare.account.BillingCountry) {
		   result = -1;
		}
		return result;
    }
}