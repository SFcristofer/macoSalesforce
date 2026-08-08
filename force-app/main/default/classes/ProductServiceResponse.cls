public class ProductServiceResponse {

    public ProductServiceResponse(Product2 prod) {
        nombreProd = prod.Name;
        prodName = prod.ProductName__c;
        medidasAgr = prod.Medidas_del_Producto_Agrupadas2__c;
        color = prod.Color2__c;
        codProd = prod.ProductCode;
        
        codEAN = prod.Codigo_EAN2__c;
        codDUN = prod.Codigo_DUN_14__c;
        codArancel = prod.CodigoArancelario__c;
        //tipoReg = prod.ProductCode;
        activo = prod.IsActive;
        familia = prod.Family;
        subfam = prod.Subfamilia__c;
        clase = prod.Clase__c;
        marcab = prod.Marca__c;
        marcaif = prod.MarcaItemDeFactura__c;
        pckPers = prod.PackagingPersonalizado__c;
        descr = prod.Description;
        material = prod.Material__c;
        compPerc = prod.ComposicionEnPorcentaje__c;
        listCat = prod.Listado_en_catalogo__c;
        garantia = prod.Garantia__c;
        manuali = prod.ManualDeInstrucciones__c;
        proddet = prod.Producto_detalle__c;
        prodlrg = prod.ProductoLargoCm__c;
        prodanch = prod.ProductoAnchoCm__c;
        prodalt = prod.ProductoAltoCm__c;
        proddiam = prod.ProductoDiametroCm__c;
        prodvol = prod.ProductoM3__c;
        prodvolc = prod.Volumen_Producto_m3__c;
        prodnw = prod.ProductoPesoKg__c;
        prodgw = prod.G_W_del__c;
        
        imagen1 = prod.IDImagen1__c;
        imagen2 = prod.IDImagen2__c;
        imagen3 = prod.IDImagen3__c;
        imagen4 = prod.IDImagen4__c;
    }

    public String nombreProd {set; get;}
    public String prodName {set; get;}
    public String medidasAgr {set; get;}
    public String color {set; get;}
    public String codProd {set; get;}
    
    public String codEAN {set; get;}
    public String codDUN {set; get;}
    public String codArancel {set; get;}
    public String tipoReg {set; get;}
    public Boolean activo {set; get;}
    public String familia {set; get;}
    public String subfam {set; get;}
    public String clase {set; get;}
    public String marcab {set; get;}
    public String marcaif {set; get;}
    public String pcking {set; get;}    
    public String pckPers {set; get;}
    public String descr {set; get;}
    public String material {set; get;}
    public String compPerc {set; get;}
    public Boolean listCat {set; get;}
    public Boolean garantia {set; get;}
    public Boolean manuali {set; get;}
    public String proddet {set; get;}
    public String prodlrg {set; get;}
    public String prodanch {set; get;}
    public String prodalt {set; get;}
    public String proddiam {set; get;}
    public Decimal prodvol {set; get;}
    public Decimal prodvolc {set; get;}
    public Decimal prodnw {set; get;}
    public Decimal prodgw {set; get;}
    
    public String imagen1 {set; get;}
    public String imagen2 {set; get;}
    public String imagen3 {set; get;}
    public String imagen4 {set; get;}
}