/*
 * Controlador de VF (ReporteMargenDetail.page)
 */
public with sharing class ReporteMargenDetail 
{ 
    private static final String OPP_STATUS_CLOSED_WON = 'Cerrada/Ganada';
	public Date fechaIni;
	public Date fechaFin;
	public Date today;
	public Integer currentYear {set; get;}	

	public String idCliente {get; set;}
	public String country {get; set;}	
	public String recordTypeId;
	private List<String> idsParentClientes;
	private List<String> idsClientes;	
    public List<ClienteContactoMargen> clientesContacto {get; set;}

    private Map<String, ClienteContactoMargen> clientesContactoMap;	

	public Decimal costoTotalGeneral {set; get;}
	public Decimal importeVentaNetoGeneral {set; get;}
	public Decimal margenReal {set; get;}
	public Decimal objetivoVentaGeneral {set; get;}
	public Decimal margenObjetivoGeneral {set; get;}
    public Decimal objetivoVentaMargen {set; get;}
    public Decimal objetivoVentaMargenTotal {set; get;}
    public Decimal desviacionTotal {set; get;}
    public Decimal desviacionMargenTotal {set; get;}


    /*
	 * Constructor
	 * El reporte recibe dos parametros:
	 *
	 * idCliente = Id del cliente del que se deesean conocer sus datos
     * Ejemplo: ReporteMargenDetail?idCliente=0014600001HKs9aAAD  
	 *
	 * country = Reporte por pais
     * Ejemplo: ReporteMargenDetail?country=COLOMBIA
	 */
	public ReporteMargenDetail()  {
        System.debug('Cosntructor - ReporteMargenDetail');
        idCliente  = ApexPages.CurrentPage().getparameters().get('idCliente');
        country  = ApexPages.CurrentPage().getparameters().get('country');		
		System.debug('idCliente [' + idCliente + ']');

		desviacionMargenTotal = 0;
		objetivoVentaMargenTotal = 0;
						
        today = Date.today();
        fechaIni = Date.newInstance(today.year(),1,1);//ymd Date.newInstance(2018,1,1);
        fechaFin = Date.newInstance(today.year(),12,31);//Date.newInstance(2018,12,31);
		currentYear = today.year();
        initData();
	}

    /** 
     *	Inicializa los datos que se mostraran en el rpeorte
	 */
	public void initData() {
      recordTypeId = getRecordTypeId('Cliente/Contacto');
	  loadClientes(recordTypeId);
	  relatePedidosClientes();
      relatePlanificacionComercialCliente();	  
	  calculateData();
	  calculateMargins();
	  calculateTotales();
	  clientesContacto.sort();
	}

    /*
	 * Se obtiene la coleccion de clientes de los que se va a mostrar su informacion
	 */
	public List<Account> loadClientes(String recordTypeId) {
		String nameAux;
		String[] tokens;
        ClienteContactoMargen clienteContacto;
        List<Account> clientes;
		idsParentClientes = new List<String>();
		idsClientes = new List<String>();		
        clientesContacto = new List<ClienteContactoMargen>();
		clientesContactoMap = new Map<String, ClienteContactoMargen>();

		if(idCliente == null) {
            clientes = getClientes();
		}
		if(idCliente != null) {
		    clientes = getClientes(idCliente);
		}
		if(country != null) {
		    clientes = getClientesCountry(country);
		}

		System.debug('clientes.size() [' + clientes.size() + ']');
        for(Account cliente : clientes) {
           nameAux = cliente.Name;
           clienteContacto = new ClienteContactoMargen(cliente);

		   if(nameAux != null) {
              tokens = nameAux.split('-');
			  if(tokens.size() == 2) {
			    clienteContacto.cliente = tokens[0].trim();
			    clienteContacto.comprador = tokens[1].trim();
			  }
			  if(tokens.size() == 1) {
			    clienteContacto.cliente = tokens[0].trim();
			  }
		   }

		   if(cliente.ParentId != null) {
              idsParentClientes.add(cliente.ParentId);
		   }
		   idsClientes.add(cliente.Id);
		   clientesContacto.add(clienteContacto);
		   clientesContactoMap.put(clienteContacto.idCliente, clienteContacto);
		}
		return clientes;
	}

    /*
	 * Se obtiene la coleccion de pedidos y se asocia con la coleccion de clientes
	 */
	public void relatePedidosClientes() {
       ClienteContactoMargen clienteContacto;
       List<Opportunity> opps;	   

	   opps = [SELECT Id, 
	                  Name,
					  AccountId,
                      PlanificacionComercial__c,
                      PlanificacionComercial__r.Inicio__c,
                      PlanificacionComercial__r.Fin__c,
                      PlanificacionComercial__r.ObjetivoDeVentas__c,
                      PlanificacionComercial__r.Ventas__c,
                      PlanificacionComercial__r.ObjetivoDeVentasNeto__c,
                      PlanificacionComercial__r.Objetivo_de_Margen__c,
					  PlanificacionComercial__r.Cuenta__r.Name,
                      Costo_Estimado__c,
					  Importe_Neto2__c,
					  CurrencyIsoCode
                 FROM Opportunity
                WHERE PlanificacionComercial__r.Inicio__c >= :fechaIni
                  AND PlanificacionComercial__r.Fin__c <= :fechaFin
                  AND AccountId IN :idsClientes
				  AND StageName = :OPP_STATUS_CLOSED_WON];

       for(Opportunity opp : opps) {
           clienteContacto = clientesContactoMap.get(opp.AccountId);
		   if(clienteContacto != null) {
		     clienteContacto.addOportunidad(opp);
		   }
	   }
	}


    /*
	 * Se obtiene la coleccion de planificaciones comerciales y se asocia a la coleccion de clientes
	 */
	public void relatePlanificacionComercialCliente() {
       ClienteContactoMargen clienteContacto;
       List<PlanificacionComercial__c> pcList;	   

	   pcList = [SELECT Id, 
                        Name, 
                        Activa__c, 
                        Inicio__c, 
                        Fin__c,
                        Cuenta__c,
						Cuenta__r.Name,
                        ObjetivoDeVentas__c,
                        Ventas__c,
                        ObjetivoDeVentasNeto__c,
						Objetivo_de_Margen__c,
						CurrencyIsoCode						
                   FROM PlanificacionComercial__c
                  WHERE Activa__c = true
				    AND Cuenta__c = :idsClientes
                    AND Inicio__c >= :fechaIni
                    AND Fin__c <= :fechaFin];

       for(PlanificacionComercial__c pc : pcList) {
           clienteContacto = clientesContactoMap.get(pc.Cuenta__c);
		   if(clienteContacto != null) {
		     clienteContacto.addPlanificacionComercial(pc);
		   }
	   }
	}


    /*
	 * Se obtiene la coleccion de clientes cuyo tipo de registro es "Cliente/Contacto"
	 */
	public List<Account> getClientes() {
        List<Account> clientes;
        clientes = [SELECT Id, 
		                   Name,
						   BillingCountry,
						   ParentId,
						   CurrencyIsoCode,
						   ContactoComercial__c,
						   Id_Externo__c
		              FROM Account
					 WHERE RecordTypeId = :recordTypeId];
        return clientes;
	}

    /*
	 * Se obtiene la coleccion de clientes por Id
	 */
	public List<Account> getClientes(String idCliente) {
        List<Account> clientes;
        clientes = [SELECT Id, 
		                   Name,
						   BillingCountry,
						   ParentId,
						   CurrencyIsoCode,
						   ContactoComercial__c,
						   Id_Externo__c
		              FROM Account
					 WHERE RecordTypeId = :recordTypeId
					   AND Id = :idCliente];
        return clientes;
	}

    /*
	 * Se obtiene la coleccion de clientes por pais
	 */
	public List<Account> getClientesCountry(String country) {
        List<Account> clientes;
        clientes = [SELECT Id, 
		                   Name,
						   BillingCountry,
						   ParentId,
						   CurrencyIsoCode,
						   ContactoComercial__c,
						   Id_Externo__c
		              FROM Account
					 WHERE RecordTypeId = :recordTypeId
					   AND BillingCountry = :country];
        return clientes;
	}

    /*
	 * Se obtiene el tipo de recordtype
	 */
    public String getRecordTypeId(String name) {
		RecordType rt;
	    rt = [SELECT Id, Name FROM RecordType WHERE Name = :name AND SObjectType = 'Account'];
		return rt.Id;
	}

    /*
	 * Se calculan los datos a ser mostrados
	 */
    public void calculateData() {
		for(ClienteContactoMargen clienteContacto : clientesContacto) {
          clienteContacto.calcularDatos();
		}
	}

    /*
	 * Se calculan los datos a ser mostrados
	 */
    public void calculateMargins() {
		for(ClienteContactoMargen clienteContacto : clientesContacto) {
          clienteContacto.calculateTragetMargin();
		}
	}

    /*
	 * Se calculan los totales del reporte
	 */
    public void calculateTotales() {
	   costoTotalGeneral = 0;
	   importeVentaNetoGeneral = 0;
       margenReal = 0;
	   objetivoVentaGeneral = 0;
	   margenObjetivoGeneral = 0;
       objetivoVentaMargen = 0;

	   for(ClienteContactoMargen clienteContacto : clientesContacto) {
            objetivoVentaGeneral = objetivoVentaGeneral + clienteContacto.objetivoVentaNeta;
            costoTotalGeneral = costoTotalGeneral + clienteContacto.costoTotalGeneral;
			importeVentaNetoGeneral = importeVentaNetoGeneral + clienteContacto.importeVentaNetoGeneral;
			objetivoVentaMargen = objetivoVentaMargen + clienteContacto.objetivoVentaMargen;
       }
       if(importeVentaNetoGeneral != 0) {
           margenReal = 100 * ((importeVentaNetoGeneral - costoTotalGeneral) / importeVentaNetoGeneral);		   
	   }

       if(objetivoVentaGeneral != 0) {
           objetivoVentaMargenTotal = objetivoVentaMargen / objetivoVentaGeneral;
	   }

       if(objetivoVentaGeneral != 0) {
	      desviacionTotal = importeVentaNetoGeneral / objetivoVentaGeneral;
	   }
       if(objetivoVentaMargenTotal != 0) {
          desviacionMargenTotal = margenReal / objetivoVentaMargenTotal;
	   }
	}

}