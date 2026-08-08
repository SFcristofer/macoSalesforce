/**
*	Controller for creating Documento__c (File Wrapper)
*
*/

public class CreateEditDocument {
    
    public String parentObjectId {get;set;} //This is either a Container or a Pedido. Potentially also an Opp
    
    public list<FileInput> newContents {get;set;}
    
    public Id contentDocumentId {get;set;}
    
    public Documento__c doc{get;set;}
    
    private map<String, RecordType> recordTypes;
    
    public String recordTypeId{get;set;}
    
    public String whereTo{get;set;}
    
    // the number of new attachments to add to the list when the user clicks 'Add More'
	public static final Integer NUM_ATTACHMENTS_TO_ADD=5;
	public static final String DETAIL = Label.CREATEEDITDOC_UPLOADING_FILE_MSG;
	public static final String RT_ITEM = 'Documentacion_Articulo';
    public static final String RT_ORDER = 'Documentacion_Pedido';
	public static final String RT_PROFORMA = 'Documentacion_Proforma';
	public static final String PROF = 'Proforma';
	public static final String PEDIDO = Label.GENERIC_ORDER;
	public static final String PROLINE = 'Proforma Line Item';
    /**
    *	Captures the ParentObjectId. Creates a new Documento__c and links it to the parent (type dependent)
    *	Possible parent types: PedidoDeCompra__c, Compra__c.
    */
    public CreateEditDocument(){
    	parentObjectId = ApexPages.currentPage().getParameters().get('id');
    	recordTypes = new map<String, RecordType>();
        for(RecordType rt : [SELECT Id,
    							DeveloperName
                                FROM RecordType
                             WHERE sObjectType = 'Documento__c']){
        	recordTypes.put(rt.DeveloperName, rt);           
        }
    	String orderPrefix = Schema.SObjectType.PedidoDeCompra__c.getKeyPrefix();
    	String itemPrefix = Schema.SObjectType.PedidoLineItem__c.getKeyPrefix(); //Probably not needed
    	String proformaPrefix = Schema.SObjectType.Proforma__c.getKeyPrefix();
    	doc = new Documento__c();
    	if(parentObjectId.startsWith(orderPrefix)){
    		doc.PedidoDeCompra__c = parentObjectId;
    		doc.RecordTypeId = recordTypes.get(RT_ORDER).Id;
    		PedidoDeCompra__c c = [SELECT Name,
    								Proforma__r.Cuenta__r.Name
    								FROM PedidoDeCompra__c
    								WHERE id = :parentObjectId];
    		whereTo = DETAIL.replace('{0}', PEDIDO).replace('{1}', c.Name).replace('{2}', c.Proforma__r.Cuenta__r.Name);
    	}else if(parentObjectId.startsWith(itemPrefix)){
    		doc.PedidoLineItem__c  = parentObjectId;
    		doc.RecordTypeId = recordTypes.get(RT_ITEM).Id;
    		PedidoLineItem__c i = [SELECT Name,
    								PedidoDeCompra__r.Proforma__r.EstudioOportunidad__r.Oportunidad__r.Account.Name
    								FROM PedidoLineItem__c
    								WHERE id = :parentObjectId];
    		whereTo = DETAIL.replace('{0}', PROLINE).replace('{1}', i.Name).replace('{2}'
									, i.PedidoDeCompra__r.Proforma__r.EstudioOportunidad__r.Oportunidad__r.Account.Name);
    	}else if(parentObjectId.startsWith(proformaPrefix)){
    		doc.Proforma__c = parentObjectId;
    		doc.RecordTypeId = recordTypes.get(RT_PROFORMA).Id;
    		Proforma__c c = [SELECT Name,
    								Cuenta__r.Name
    								FROM Proforma__c
    								WHERE id = :parentObjectId];
    		whereTo = DETAIL.replace('{0}', PROF).replace('{1}', c.Name).replace('{2}', c.Cuenta__r.Name);
		}
    	newContents = new List<FileInput>{new FileInput()};
    	
    }
    
    
    // Add more attachments action method
	public void addMore()
	{
		// append NUM_ATTACHMENTS_TO_ADD to the new attachments list
		for (Integer i = 0; i < NUM_ATTACHMENTS_TO_ADD; i++)
		{
			newContents.add(new FileInput());
		}
	}    
	
	// Save action method
	// change return type back to void if uploading more is required
	public PageReference saveChanges()
	{
		if (doc.Id == null){
            doc.Name = doc.Tipo_de_Documento__c;
            try{
			    insert doc;
            }catch (DmlException dml){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,dml.getDmlMessage(0)));
                return null;
            }
		}
		List<ContentVersion> toInsert=new List<ContentVersion>();
		for (FileInput newC : newContents)
		{
			if (newC.fileBody != null)
			{
				ContentVersion cv = new ContentVersion();
				cv.ContentLocation = 'S';
        		cv.ContentDocumentId = contentDocumentId;
        		cv.VersionData = newC.fileBody;
        		cv.Title = newC.fileName;
        		cv.PathOnClient = newC.fileName;
        		toInsert.add(cv);
			}
		}
		insert toInsert;
		
		if(!toInsert.isEmpty()){
			ContentVersion ppal = [SELECT ContentDocumentId
									FROM ContentVersion
									WHERE Id = :toInsert[0].Id
									limit 1];
			doc.Archivo_Principal__c = ppal.ContentDocumentId;
			update doc;
		}

		set<Id> insertedContentIds = new set<Id>();
		for (ContentVersion c : toInsert){
			insertedContentIds.add(c.Id);
		}
		
		toInsert = [SELECT Id, 
        				ContentDocumentId
        				FROM ContentVersion
        				WHERE Id IN :insertedContentIds];
        
        list<ContentDocumentLink> links = new list<ContentDocumentLink>();
        
        for(ContentVersion c : toInsert){
			ContentDocumentLink cdl = new ContentDocumentLink();
			cdl.ContentDocumentId = c.ContentDocumentId;
        	cdl.LinkedEntityId = doc.Id;
        	cdl.ShareType = 'I';
        	links.add(cdl);
        }
        
		insert links;

		newContents.clear();
		newContents.add(new FileInput());
		
		return new PageReference('/' + parentObjectId);
	}
	
	// Action method when the user is done
	public PageReference done()
	{
		// send the user to the detail page for the sobject
		return new PageReference('/' + parentObjectId);
	}

	public class FileInput{
		public transient blob fileBody{get;set;}
    	public String fileName{get;set;}
    	public String description{get;set;}
    	
    }
}