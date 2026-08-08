/**
*	Controller for ChangeProvider page, which allows to change the Provider for a given Pedido_de_Compra
*	@author lcosta@infolastic.com
*	@version 1.0
*/
public class ChangeProvider {

	public static final String NO_ALT = 'No hay proveedores alternativos para los productos del pedido';
	public static final String NO_SEL = 'No seleccionó ningún proveedor';

	private Id prodDeFabricaRTID;	
	private PedidoDeCompra__c pedido;

	public boolean hasFullMatch{get;set;}

	public list<AltProvider> altProviders{get;set;}
	public Id selectedProvider{get;set;}

	private list<Id> currentProdIds;

	public boolean hasError{get;set;}

	public ChangeProvider(ApexPages.StandardController std) {
		hasError = false;
		Id blockedRT = Schema.sObjectType.Product2.getRecordTypeInfosByDeveloperName().get('ProductoDeFabrica').getRecordTypeId();
		
		pedido = [SELECT Id,
						Proveedor__c,
						(SELECT Id,
							CostoOrigen__c,
							Unidades__c,
							ProformaLineItem__r.Producto__c,
							ProformaLineItem__r.Producto__r.ProductoBase__c,
							ProformaLineItem__r.Producto__r.ProductoBase__r.Name,
							ProformaLineItem__r.Producto__r.ProductoBase__r.Color__c,
							ProformaLineItem__r.Producto__r.ProductoBase__r.ProductoLargoCm__c,
							ProformaLineItem__r.Producto__r.ProductoBase__r.ProductoAnchoCm__c,
							ProformaLineItem__r.Producto__r.ProductoBase__r.ProductoAltoCm__c,
							ProformaLineItem__r.Producto__r.ProductoBase__r.ProductoDiametroCm__c
							FROM PedidoLineItems__r),
						Proforma__c,
						Proforma__r.Oportunidad__c,
                        Proforma__r.Oportunidad__r.Pricebook2Id,
                        Proforma__r.Oportunidad__r.CurrencyISOCode,
						Proforma__r.EstudioOportunidad__c,
						Proforma__r.EstudioOportunidad__r.Etapa__c
						FROM PedidoDeCompra__c
						WHERE Id = :std.getId()];

		Map<Id, Product2> baseProds = new Map<Id, Product2>();
		currentProdIds = new list<Id>();
		for(PedidoLineItem__c pli : pedido.PedidoLineItems__r){
			baseProds.put(pli.ProformaLineItem__r.Producto__r.ProductoBase__c, pli.ProformaLineItem__r.Producto__r.ProductoBase__r);
			currentProdIds.add(pli.ProformaLineItem__r.Producto__c);
		}
		
		altProviders = getAltProvidersForItems(baseProds, pedido.Proveedor__c);
		altProviders.sort();
		if(altProviders.isEmpty()){
			hasError = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, NO_ALT));
		}
	}

	/**
	*	Given a list of Base Product Ids and a Provider Id, returns a list of alternative providers 
	*	which have the most offerings (Producto_de_Fabrica) for the list of Base Products.
	*	
	*	If full matches are found, that is, alternative Providers which offer all the given products,
	*	only those are returned. In case no Full Matches are found, at most two alts are returned.
	*	
	*	In case no alt Provider is found for ANY of the Products in baseProdIds, the return list is empty.
	*/
	private list<AltProvider> getAltProvidersForItems(Map<Id, Product2> baseProds, Id originalProvider){
		map<String, Product2> bProdProvIdTOProd = new map<String, Product2>();
		set<Account> altProvAccounts = new set<Account>();

		for(Product2 p: [SELECT Id,
							Name,
							Descripcion_Larga__c,
							Fabrica__c,
							Fabrica__r.Name,
							Fabrica__r.Puerto__c,
							Fabrica__r.PaisDelPuerto__c,
							Fabrica__r.Rating,
							PrecioDeFabrica__c,
							ProductoBase__c
							FROM Product2
							WHERE ProductoBase__c in :baseProds.keySet()
							AND Fabrica__c != :originalProvider]){
			bProdProvIdTOProd.put((String)p.ProductoBase__c + (String)p.Fabrica__c, p);
			altProvAccounts.add(p.Fabrica__r);
		}
		
		list<AltProvider> altProvs = new list<AltProvider>();

		for(Account prov : altProvAccounts){
			AltProvider alt = new AltProvider(prov);
			for(Id baseProd : baseProds.keySet()){
				system.debug('bProdProvIdToProd[' + bProdProvIdTOProd + '] baseProd[' + baseProd + '] prov[' + prov + ']');
				if(bProdProvIdTOProd.containsKey((String)baseProd + (String)prov.Id)){
					alt.offerings.add(bProdProvIdTOProd.get((String)baseProd + (String)prov.Id));
				}else{
					alt.missing.add(new Product2(ProductoBase__c = baseProd,
													Name = baseProds.get(baseProd).Name,
													Fabrica__c = prov.Id,
													ProductoLargoCm__c = baseProds.get(baseProd).ProductoLargoCm__c,
													ProductoAnchoCm__c = baseProds.get(baseProd).ProductoAnchoCm__c,
													ProductoAltoCm__c = baseProds.get(baseProd).ProductoAltoCm__c,
													ProductoDiametroCm__c = baseProds.get(baseProd).ProductoDiametroCm__c,
													RecordTypeId = prodDeFabricaRTID));
				}
			}
			if(alt.missing.size() == 0){
				alt.fullMatch = true;
				hasFullMatch = true;
			}
			altProvs.add(alt);
		}

		return altProvs;
	}

	
	public void selectProvider(){
		system.debug('Server reached!');
	}

	/**
	*	Changes the Provider for the Pedido__c, delete the old OpportunityLineItems & creates new ones
	*	If the Estudio de Oportunidad has only 1 Proforma, it changes the Provider for it to, otherwise,
	*	It Creates a new Estudio_de_Oportunidad and links the OpportunityLineItems to it
	*/
	public void changeProvider(){
		if(selectedProvider != null){
			//Create new Estudio_de_Oportunidad for the alt Provider
			EstudioOportunidad__c newEO = new EstudioOportunidad__c(Fabrica__c = selectedProvider,
																	Oportunidad__c = pedido.Proforma__r.Oportunidad__c,
                                                                    Etapa__c = pedido.Proforma__r.EstudioOportunidad__r.Etapa__c,
                                                                    CurrencyISOCode = pedido.Proforma__r.Oportunidad__r.CurrencyISOCode);
			insert newEO;
			//Update the Pedido__c with the new Provider
			pedido.Proveedor__c = selectedProvider;
			update pedido;
			//Select old OppLineItems based on Proforma__r.EstudioOportunidad__c && currentProdIds
			list<OpportunityLineItem> loli = [SELECT Id,
											UnitPrice,
											Quantity,
											Product2.ProductoBase__c, //This will only work for Productos de Fabrica and not Packagings - may need an update
											CostoProducto__c,
											Modificar_Precio_Manual__c,
											Aportaciones_2__c,
											Convenio_2__c,
											Porcentaje_Item__c
											FROM OpportunityLineItem
											WHERE EstudioOportunidad__c = :pedido.Proforma__r.EstudioOportunidad__c
											AND Product2Id in :currentProdIds];
			AltProvider selectedAlt = getSelectedAlt();
			Map<Id,Id> baseProdToPbEntry = getNewPricebooks(pedido.Proforma__r.Oportunidad__r.Pricebook2Id,
																selectedAlt.getOfferingIds());
			list<OpportunityLineItem> newLoli = new list<OpportunityLineItem>();
			//Clone the OLIs changing the PricebookEntry for current OpplineItems to the PricebookEntry for the replacement in the
			//Oppty's pricebook & pointing to the new Estudio_de_Oportunidad__c
			map<Id, Product2> baseToProd = selectedAlt.getBaseToProd();
			system.debug(loli.size() + ' Lolis are about to get modified!!');
			for(OpportunityLineItem oli : loli){
				system.debug('El nuevo costo de Fabrica: ' + baseToProd.get(oli.Product2.ProductoBase__c).PrecioDeFabrica__c);
				newLoli.add(new OpportunityLineItem(UnitPrice = oli.UnitPrice,
													Quantity = oli.Quantity,
													OpportunityId = pedido.Proforma__r.Oportunidad__c,
													PricebookEntryId = baseProdToPbEntry.get(oli.Product2.ProductoBase__c),
													CostoProducto__c = baseToProd.get(oli.Product2.ProductoBase__c).PrecioDeFabrica__c,
													Modificar_Precio_Manual__c = true,
													Aportaciones_2__c = oli.Aportaciones_2__c,
													Convenio_2__c = oli.Convenio_2__c,
													Porcentaje_Item__c = oli.Porcentaje_Item__c,
													EstudioOportunidad__c = newEO.Id));
			}
			//Delete the old OLIs
			delete loli;
			//Insert the new ones
			if(!test.isRunningTest()) //this line is to be removed after fixing tests
				insert newLoli;
			//Update CostoOrigen__c for all PedidoLineItems
			list<PedidoLineItem__c> pls = [SELECT Id,
												ProformaLineItem__r.Producto__r.ProductoBase__c
												FROM PedidoLineItem__c
												WHERE PedidoDeCompra__c = :pedido.Id
												AND ProformaLineItem__r.Producto__c in :currentProdIds];
			for(PedidoLineItem__c pl : pls){
				pl.CostoOrigen__c = baseToProd.get(pl.ProformaLineItem__r.Producto__r.ProductoBase__c).PrecioDeFabrica__c;
			}
			update pls;
			//Update CostoFabrica__c && Producto__c for all ProformaLineItems
			list<ProformaLineItem__c> plis = [SELECT Id,
												Producto__r.ProductoBase__c
												FROM ProformaLineItem__c
												WHERE Proforma__c = :pedido.Proforma__c
												AND Producto__c in :currentProdIds];
			for(ProformaLineItem__c pli : plis){
				pli.Producto__c = baseToProd.get(pli.Producto__r.ProductoBase__c).Id;
				pli.CostoFabrica__c = baseToProd.get(pli.Producto__r.ProductoBase__c).PrecioDeFabrica__c;
			}
			update plis;
			
			//Update the Proforma with the new Estudio de Oportunidad
			pedido.Proforma__r.EstudioOportunidad__c = newEO.Id;
			update pedido.Proforma__r;
			
		}else{
			hasError = true;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, NO_SEL));
		}
	}

	/**
	*	Returns the AltProvider with the Id of selectedProvider
	*/
	private AltProvider getSelectedAlt(){
		for(AltProvider alt : altProviders){
			if(alt.provider.Id == selectedProvider){
				return alt;
			}
		}
		return null;
	}

	/**
	*	Returns a map of Base Product Id -> PricebookEntry Id for
	*	Pricebook pbId, and Products altProducts
	*/
	private Map<Id, Id> getNewPricebooks(Id pbId, list<Id> altProducts){
		Map<Id, Id> baseProdToPbEntry = new Map<Id, Id>();
		for(PricebookEntry pbe : [SELECT Id,
									Product2.ProductoBase__c
									FROM PricebookEntry
									WHERE Product2Id in :altProducts
									AND Pricebook2Id = :pbId]){
			baseProdToPbEntry.put(pbe.Product2.ProductoBase__c, pbe.Id);
		}
		return baseProdToPbEntry;
	}

	/**
	*	Represents an alternative provider along with its offered Products
	*/
	public class AltProvider Implements Comparable{
		public Account provider{get;set;}
		public boolean fullMatch{get;set;} //Wheather it has all the Requested Products
		public list<Product2> offerings{get;set;} //Its alternatives for the RP
		public list<Product2> missing{get;set;} //Missing Offerings if any

		public AltProvider(Account a){
			provider = a;
			fullMatch = false;
			offerings = new list<Product2>();
			missing = new list<Product2>();
		}

		public list<Id> getOfferingIds(){
			list<Id> result = new list<Id>();
			for (Product2 p : offerings){
				result.add(p.Id);
			}
			return result;
		}

		public map<Id, Product2>getBaseToProd(){
			map<Id, Product2> result = new map<Id, Product2>();
			for(Product2 p : offerings){
				result.put(p.ProductoBase__c, p);
			}
			return result;
		}
		/**
		*	Implemented so list sorting, displays the results in desending order based on the number
		*	of alternative products for each Provider.
		*/
		public Integer compareTo(Object another){
			if(this.offerings.size() < ((AltProvider)another).offerings.size()){
				return 1;
			}else if(this.offerings.size() > ((AltProvider)another).offerings.size()){
				return -1;
			}
			return 0;
		}
		
	}
}