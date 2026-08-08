public class ConsolidarProformaController {
    
    private String idProforma;
    public Proforma__c proforma {set; get;}
    public List<Proforma__c> proformas {set; get;}
    public List<ProformaWrapper> proformasPorAgrupar {set; get;}
    public List<ProformaWrapper> proformasSelected {set; get;}

    public ConsolidarProformaController(ApexPages.StandardController stdController) {
		idProforma = ApexPages.CurrentPage().getparameters().get('id');

        proforma = DOBrandsDAO.getProformaBase(idProforma);
        proformas = DOBrandsDAO.getProformas(idProforma, proforma.Cuenta__c, proforma.Oportunidad__r.PlanificacionComercial__c);
        proformasPorAgrupar = new List<ProformaWrapper>();

        createProformasWrapers();
    }


    private void createProformasWrapers() {
        ProformaWrapper pw;
        for(Proforma__c p : proformas) {
            pw = new ProformaWrapper(p);
            pw.selected = false;
            proformasPorAgrupar.add(pw);
        }
    }

    public PageReference mostrarProformasAgrupadas() {
        proformasSelected = new List<ProformaWrapper>();
        for(ProformaWrapper prfs : proformasPorAgrupar) {
            if(prfs.selected) {
                proformasSelected.add(prfs);
            }
        }

		PageReference pageRef = new PageReference('/apex/ConsolidarProformaAgrupadas');
		pageRef.setRedirect(false);
		return pageRef;
    }


    public PageReference agruparProformas() {
        
        updateParent(proforma, proformasSelected);
        return new PageReference('/' + idProforma);
    }

    private void updateParent(Proforma__c proformaBase, List<ProformaWrapper> proformasToUpdate) {
        List<PedidoDeCompra__c> pedidosCompra;
        List<PedidoDeCompra__c> pedidosCompraUpdate = new List<PedidoDeCompra__c>();        
        List<ProformaLineItem__c> proformaLItems;
        List<ProformaLineItem__c> proformaLItemsUpdate = new List<ProformaLineItem__c>();
        List<Proforma__c> proformasDelete = new List<Proforma__c>();
        List<String> idsProformasConsolidadas = new List<String>();

        List<Documento__c> docs;

        Proforma__c proformaToUpdate;
        for(ProformaWrapper pfw : proformasToUpdate) {
            proformaToUpdate = pfw.proforma;
            proformaLItems = proformaToUpdate.ProformaLineItems__r;
            pedidosCompra = proformaToUpdate.PedidosDeCompra__r;

            idsProformasConsolidadas.add(pfw.proforma.Id);
            proformasDelete.add(pfw.proforma);

            for(ProformaLineItem__c prli : proformaLItems) {
                prli.Proforma__c = proformaBase.Id;
                proformaLItemsUpdate.add(prli);
            }

            for(PedidoDeCompra__c pc : pedidosCompra) {
                pc.Proforma__c = proformaBase.Id;
                pedidosCompraUpdate.add(pc);
            }
        }

        System.debug('PC: ' + idsProformasConsolidadas);
        docs = DOBrandsDAO.getDocumentosProforma(idsProformasConsolidadas);
        for(Documento__c doc : docs) {
            doc.Proforma__c = proformaBase.Id;
        }

        for(Documento__c doc : docs) {
            System.debug('D id[' + doc.Id + '] pr[' + doc.Proforma__c + '] name[' + doc.Name + ']');
        }

        for(ProformaLineItem__c prli : proformaLItemsUpdate) {
            System.debug('id[' + prli.Id + '] pr[' + prli.Proforma__c + '] name[' + prli.Name + ']');            
        }

        for(PedidoDeCompra__c pc : pedidosCompraUpdate) {
            System.debug('id[' + pc.Id + '] pr[' + pc.Proforma__c + '] name[' + pc.Name + ']');            
        }


        for(Proforma__c p : proformasDelete) {
            System.debug('id[' + p.Id + '] prN[' + p.name + ']');
        }

        update docs;
        update pedidosCompraUpdate;
        update proformaLItemsUpdate;
        delete proformasDelete;
    }

    public class ProformaWrapper {
        public Boolean selected {set; get;}
        public Proforma__c proforma {set; get;}

        public ProformaWrapper(Proforma__c pproforma) {
            proforma = pproforma;
        }
    }

}