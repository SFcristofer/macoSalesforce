public class AgentMailController 
{
	private PedidoDeCompra__c pedido;
	public Account topParent {set; get;}
    public String nameTopParent {set; get;}
	public Sociedades__mdt sociedad {set; get;}

	public AgentMailController(ApexPages.StandardController stdController) {
       String idAgente;
	   String parentId;
	   String strSociedad;
       this.pedido = (PedidoDeCompra__c)stdController.getRecord();
	   System.debug('pedido [' + pedido + ']');
	   pedido = getPedidoCompra(pedido.Id);
	   strSociedad = DOBrandsDAO.getSociedadFromOrder(pedido.Id);
	   sociedad = DOBrandsDAO.getSociedadInfo(strSociedad);
	   getPedidoLineItems(pedido.Id);
	   getCliente(pedido.Proforma__r.Cuenta__c);
	   getClienteParent(pedido.Proforma__r.Cuenta__c);	   
	   System.debug('pedidoid [' + pedido.Id + ']');
	   System.debug('proforma [' + pedido.Proforma__c + ']');
	   System.debug('cuenta [' + pedido.Proforma__r.Cuenta__c + ']');
	   parentId = pedido.Proforma__r.Cuenta__r.ParentId;
	   parentId = pedido.Proforma__r.Cuenta__r.ParentId;
	   System.debug('parent [' + parentId + ']');
	   if(parentId != null) {
	     topParent = getTopParent(parentId);
		 nameTopParent = topParent.Name;
	   } else {
          nameTopParent = pedido.Proforma__r.Cuenta__r.Name;
	   }
	}


    private Account getTopParent(String accountId) {
		Account acct;
        System.debug('accountId GTP [' + accountId + ']');
		acct = [SELECT Id, 
                       Name,
					   Consignee_Linea_1__c,
					   Consignee_Linea_2__c,
					   Consignee_Linea_3__c,
					   Consignee_Linea_4__c,
					   Consignee_Linea_5__c,
					   Consignee_Linea_6__c,
					   Notify_Party_Linea_1__c,
					   Notify_Party_Linea_2__c,
					   Notify_Party_Linea_3__c,
					   Notify_Party_Linea_4__c,
					   Notify_Party_Linea_5__c,
					   Notify_Party_Linea_6__c,
					   Notify_Party_Linea_7__c,
					   Delivery_Agent_Address_1__c,
					   Delivery_Agent_Address_2__c,
					   Delivery_Agent_Address_3__c,
					   Delivery_Agent_Address_4__c,
					   Delivery_Agent_Company__c,
					   Delivery_Agent_CTC__c,
					   Delivery_Agent_Phone__c,
					   ParentId
                  FROM Account
                 WHERE Id = :accountId];
        
		if(acct.ParentId != null)
		{
           acct = getTopParent(acct.ParentId);
		}
        return acct;
	}


    private PedidoDeCompra__c getPedidoCompra(String idPedido)
	{
		PedidoDeCompra__c pedido;
		pedido = [SELECT Id,
		                 Name,
						 Cuenta_Agente_DO__c,
						 Proforma__r.Cuenta__c,
						 Proforma__r.Cuenta__r.ParentId,
						 Proforma__r.Cuenta__r.Name
                    FROM PedidoDeCompra__c
                   WHERE Id = :idPedido];
        return pedido;
	}

	private List<PedidoLineItem__c> getPedidoLineItems(String idPedido)
	{
		List<PedidoLineItem__c> items;
		items = [SELECT Id, Name FROM PedidoLineItem__c WHERE PedidoDeCompra__c = :idPedido];
        return items;
	}

    private Account getCliente(String pidCliente)
	{
        Account cliente;
		cliente = [SELECT Id, Name, ParentId FROM Account WHERE Id = :pidCliente];
		System.debug('get parent [' + cliente.parentId + ']');
		return cliente; 
	} 

    private Account getClienteParent(String pidCliente)
	{
        Account cliente;
		cliente = [SELECT Id, Name, ParentId FROM Account WHERE Id = :pidCliente];
		System.debug('get parent [' + cliente.parentId + ']');
		return cliente; 
	} 

}