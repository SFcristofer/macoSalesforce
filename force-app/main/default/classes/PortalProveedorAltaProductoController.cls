public class PortalProveedorAltaProductoController {
    private static String UNAVAILABLE_TOKEN = Label.PORTAL_UNAVAILABLE_TOKEN;
    private static String INVALID_TOKEN = Label.PORTAL_INVALID_TOKEN;

    public String token {set; get;}
    public Account provider {set; get;}
    //public Product2 product {set; get;}
    public Producto_Portal__c product {set; get;}
    public Product2 productBase {set; get;}

    public String idUserTask {set; get;}

    public Boolean isButtonAddProdEnabled {set; get;}
    public Boolean isFinish {set; get;}

    public Boolean isPageShowed {set; get;}

//------------------------------------ Images

	public list<ProdImage> prodImageList {get;set;}
	//public Product2 product {get;set;}
	public static final String IMAGE_FOLDER = '00l46000000I4dX';
	public static final String NO_IMAGE = '015460000005lAl';
	public static final String IMG1 = 'Imagen 1';
	public static final String IMG2 = 'Imagen 2';
	public static final String IMG3 = 'Imagen 3';
	public static final String IMG4 = 'Imagen 4';


	public Integer numProds {set; get;}   

    public PortalProveedorAltaProductoController() {
		token = ApexPages.CurrentPage().getparameters().get('dbrToken');
        System.debug('Token [' + token + ']');
        numProds = 0;
        isFinish = false;
        isPageShowed = true;
    }


    public Pagereference loadPage() {
        List<String> idUsers;
        RecordType rt;

        System.debug('Loading page ...........');

        isButtonAddProdEnabled = True;
        rt = DOBrandsDAO.getRecordType('Proveedor', 'Account');
        if(token == null) {
            System.debug('Msg [' + UNAVAILABLE_TOKEN + ']');
            isButtonAddProdEnabled = False;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, UNAVAILABLE_TOKEN));
        } else {
            provider = DOBrandsDAO.getProviderByToken(token, rt);
            if(provider == null) {
                isButtonAddProdEnabled = False;
                isPageShowed = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, INVALID_TOKEN));
            }
        }

        System.debug('provider [' + provider + ']');

         //Tarea_Aportacion__mdt
        idUsers = getIdUsersTasks();
        idUserTask = idUsers.get(0); 

        product = new Producto_Portal__c();
        if(isFinish) {
            isButtonAddProdEnabled = False;
        }

        return null;     
    }


    public Pagereference saveProduct() {
        PageReference newPage;
        RecordType rt;
        Product2 productoProspecto;
        System.debug('PDNM[' + product.Name + ']');

        productBase = createProduct(product);

        insert productBase;

        System.debug('PDNM-id[' + productBase.Id + ']');

        rt = DOBrandsDAO.getRecordType('Prospecto_de_Producto', 'Product2');
        productoProspecto = new Product2(RecordTypeId = rt.Id,
        	                             ProductoBase__c = productBase.Id,
                                         Fabrica__c = provider.Id,
                                         Name = '[Providers Portal] ' + (productBase.Name.length() > 61 ? productBase.Name.substring(0, 61) : productBase.Name),
                                         PrecioDeFabrica__c = productBase.PrecioDeFabrica__c,
                                         Codigo_Proveedor__c = productBase.Codigo_Proveedor__c,
                                         Packaging__c = productBase.Packaging__c,
                                         MOQ__c = productBase.MOQ__c,
                                         CostoPackaging__c = productBase.CostoPackaging__c,
                                         PlazoDeFabricacion__c = productBase.PlazoDeFabricacion__c);

        insert productoProspecto;

        numProds = numProds + 1;
        uploadProdImages();

        newPage = new PageReference('/apex/PortalLoadImages');
        return newPage;
    }



	private Task createTask(String subject, String description, String status, String priority, String whatId, String ownerId) {
        Task task = new Task();
        task.Subject = subject;
        task.Status = status;
        task.Priority = priority;
        task.Description = description;
        task.WhatId = whatId;
        //task.WhoId = whoId;
        task.OwnerId = ownerId;
        task.ActivityDate = System.today();
		task.isReminderSet = true;
		task.reminderDateTime = Datetime.now();
        return task;
	}


    private List<String> getIdUsersTasks() {
        List<Tarea_Aportacion__mdt> mdts;
		List<String> usersMdt;
		List<User> users;
		List<String> idUsers;

		usersMdt = new List<String>();
        idUsers = new List<String>();

        mdts = [SELECT Id, Usuario__c, MasterLabel FROM Tarea_Aportacion__mdt WHERE MasterLabel = 'portalProveedorProductos'];
        System.debug('mdts [' + mdts.size() + ']');
		
		for(Tarea_Aportacion__mdt mdt : mdts) {
            usersMdt.add(mdt.Usuario__c);
		}

        users = [SELECT Id, UserName FROM User WHERE Username IN :usersMdt];
        for(User u : users) {
            idUsers.add(u.Id);
		}
        return idUsers;
	}


    //public PageReference uploadProdImages() {
    public void uploadProdImages() {        

		System.debug('ULI-idProduct [' + productBase.Id + ']');

    	productBase = [SELECT Id,
                    Name,
					ProductCode,
					IdImagen1__c,
					IdImagen2__c,
					IdImagen3__c,
					IdImagen4__c
					FROM Product2
					WHERE Id = :productBase.Id];
		
		prodImageList = new list<ProdImage>();
		prodImageList.add(new ProdImage(productBase.IdImagen1__c, IMG1));
		prodImageList.add(new ProdImage(productBase.IdImagen2__c, IMG2));
		prodImageList.add(new ProdImage(productBase.IdImagen3__c, IMG3));
		prodImageList.add(new ProdImage(productBase.IdImagen4__c, IMG4));
    }


	// Save action method
	// change return type back to void if uploading more is required
	public PageReference saveChanges() {

        saveImages();
        
		PageReference pageRef = new PageReference('/apex/portalAltaProductos');
		pageRef.setRedirect(false);

		return pageRef;
	}


    public PageReference finish() {
        Task task;

        saveImages();

        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Thank you for registering your product(s). DO-Brands team will review them and contact you if any further information is necessary'));
        isButtonAddProdEnabled = False;
        isFinish = True;
        
        // The portal token was cleared here [Account.Portal_Token__c] (null). Now it is done in process builder

        // enviar a veronica y whatid=producto
        task = createTask('Portal-Nuevo Producto', String.valueOf(numProds) + ' product(s) has been created','Abierta', 'Normal', provider.Id, idUserTask);
        insert task;

		PageReference pageRef = new PageReference('/apex/PortalFinalizarCargaProductos');
		pageRef.setRedirect(false);
		return pageRef;
    }

	public class ProdImage {
		public transient Blob fileBody{get;set;}
    	public String fileName{get;set;}
    	public String existingImage{get;set;}
		public String label{get;set;}

		public ProdImage(String imageId, String imageLabel) {
			existingImage = imageId;
			if(existingImage == null) {
				existingImage = NO_IMAGE;
			}
			label = imageLabel;
		}
    }


    private void saveImages() {
		System.debug('portal-saveChanges [' + productBase.Id + ']');

		System.debug('prodImageList [' + prodImageList.size() + ']');

		map<String, Document> docs = new map<String, Document>();
		for(ProdImage p : prodImageList){
			if(p.fileBody != null){
				String suffix = p.label.right(1) == '1' ? '' : '_' + p.label.right(1);
		        System.debug('adding [' + prodImageList.size() + ']');
				docs.put(p.label, new Document( name = productBase.ProductCode + suffix,
												body = p.fileBody,
												folderId = IMAGE_FOLDER));
			}
		}

        System.debug('docs: ' + docs);

		if(docs.values().size() > 0){
			insert docs.values();
		}
		for(String docLabel : docs.keySet()){
			if(docLabel == IMG1){
				productBase.IdImagen1__c = docs.get(docLabel).Id;
			} else if(docLabel == IMG2){
				productBase.IdImagen2__c = docs.get(docLabel).Id;
			} else if(docLabel == IMG3){
				productBase.IdImagen3__c = docs.get(docLabel).Id;
			} else if(docLabel == IMG4){
				productBase.IdImagen4__c = docs.get(docLabel).Id;
			}
		}
		if(docs.values().size() > 0){
			update productBase;
		}

    }


    private Product2 createProduct(Producto_Portal__c productPortal) {
        Product2 prod;
        RecordType rt;
        rt = DOBrandsDAO.getRecordType('Producto', 'Product2');

        prod = new Product2(RecordTypeId = rt.Id,
                            Name = productPortal.Name,
                            CodigoArancelario__c = productPortal.CodigoArancelario__c);

        prod.Material__c = productPortal.Material__c;
        prod.ComposicionEnPorcentaje__c = productPortal.ComposicionEnPorcentaje__c;
        prod.Garantia__c = productPortal.Garantia__c;
        prod.ManualDeInstrucciones__c = productPortal.ManualDeInstrucciones__c;
        prod.Packaging__c = productPortal.Packaging__c;
        prod.Codigo_Proveedor__c = productPortal.Codigo_Proveedor__c;
        prod.PlazoDeFabricacion__c = productPortal.PlazoDeFabricacion__c;
        prod.MOQ__c = productPortal.MOQ__c;
        prod.CostoPackaging__c = productPortal.CostoPackaging__c;

        prod.Description = productPortal.Description__c;

        prod.ProductoLargoCm__c = productPortal.ProductoLargoCm__c;
        prod.ProductoAnchoCm__c = productPortal.ProductoAnchoCm__c;
        prod.ProductoAltoCm__c = productPortal.ProductoAltoCm__c;
        prod.ProductoM3__c = productPortal.ProductoM3__c;
        prod.ProductoDiametroCm__c = productPortal.ProductoDiametroCm__c;
        prod.Producto_detalle__c = productPortal.Producto_detalle__c;
        prod.ProductoPesoKg__c = productPortal.ProductoPesoKg__c;
        prod.PrecioDeFabrica__c = productPortal.PrecioDeFabrica__c;

        prod.Producto2DiametroCm__c = productPortal.Producto2DiametroCm__c;
        prod.Producto2AltoCm__c = productPortal.Producto2AltoCm__c;
        prod.Producto2AnchoCm__c = productPortal.Producto2AnchoCm__c;
        prod.Producto2LargoCm__c = productPortal.Producto2LargoCm__c;
        prod.Producto2M3__c = productPortal.Producto2M3__c;
        prod.Producto2_detalle__c = productPortal.Producto2_detalle__c;
        prod.Producto2PesoKg__c = productPortal.Producto2PesoKg__c;
        prod.Producto2PesoBruto__c = productPortal.Producto2PesoBruto__c;

        prod.Producto3DiametroCm__c = productPortal.Producto3DiametroCm__c;
        prod.Producto3AltoCm__c = productPortal.Producto3AltoCm__c;
        prod.Producto3AnchoCm__c = productPortal.Producto3AnchoCm__c;
        prod.Producto3LargoCm__c = productPortal.Producto3LargoCm__c;
        prod.Producto3M3__c = productPortal.Producto3M3__c;
        prod.Producto3_detalle__c = productPortal.Producto3_detalle__c;
        prod.Producto3PesoKg__c = productPortal.Producto3PesoKg__c;
        prod.Producto3PesoBruto__c = productPortal.Producto3PesoBruto__c;

        prod.CajaAltoCm__c = productPortal.CajaAltoCm__c;
        prod.CajaLargoCm__c = productPortal.CajaLargoCm__c;
        prod.CajaAnchoCm__c = productPortal.CajaAnchoCm__c;
        prod.CajaM3__c = productPortal.CajaM3__c;
        prod.CajaPesoKg__c = productPortal.CajaPesoKg__c;

        prod.MasterboxAltoCm__c = productPortal.MasterboxAltoCm__c;
        prod.MasterboxAnchoCm__c = productPortal.MasterboxAnchoCm__c;
        prod.MasterboxLargoCm__c = productPortal.MasterboxLargoCm__c;
        prod.MasterboxM3__c = productPortal.MasterboxM3__c;
        prod.MasterboxPesoKg__c = productPortal.MasterboxPesoKg__c;
        prod.Masterbox1_detalle__c = productPortal.Masterbox1_detalle__c;
        prod.UnidadesPorMasterBox__c = productPortal.UnidadesPorMasterBox__c;

        prod.Masterbox2AltoCm__c = productPortal.Masterbox2AltoCm__c;
        prod.Masterbox2AnchoCm__c = productPortal.Masterbox2AnchoCm__c;
        prod.Masterbox2LargoCm__c = productPortal.Masterbox2LargoCm__c;
        prod.Masterbox2M3__c = productPortal.Masterbox2M3__c;
        prod.Masterbox2PesoKg__c = productPortal.Masterbox2PesoKg__c;
        prod.Masterbox2_detalle__c = productPortal.Masterbox2_detalle__c;

        prod.Masterbox3AltoCm__c = productPortal.Masterbox3AltoCm__c;
        prod.Masterbox3AnchoCm__c = productPortal.Masterbox3AnchoCm__c;
        prod.Masterbox3LargoCm__c = productPortal.Masterbox3LargoCm__c;
        prod.Masterbox3M3__c = productPortal.Masterbox3M3__c;
        prod.Masterbox3PesoKg__c = productPortal.Masterbox3PesoKg__c;
        prod.Masterbox3_detalle__c = productPortal.Masterbox3_detalle__c;

        prod.UnidadesContainer20__c = productPortal.UnidadesContainer20__c;
        prod.UnidadesContainer40__c = productPortal.UnidadesContainer40__c;
        prod.UnidadesHQ__c = productPortal.UnidadesHQ__c;

        return prod;
    }

}