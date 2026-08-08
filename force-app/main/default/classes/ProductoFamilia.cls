public class ProductoFamilia {

    public String clave {set; get;}
    public String descripcion {set; get;}
    public String cssOrStyle {set; get;}
    public String imagen {set; get;}
    public String idHref {set; get;}
    public String imagenSF {set; get;}
    public List<ProductoSubfamilia> subfamilias {set; get;}
    public String classSubfamiliaMenu {set; get;}

    public ProductoFamilia() {
        subfamilias = new List<ProductoSubfamilia>();
        classSubfamiliaMenu = '';
    }

    public void addSubfamilia(ProductoSubfamilia psf) {
        Boolean existe = false;
        for(ProductoSubfamilia pse : subfamilias) {
            if(pse.clave.equals(psf.clave)) {
                 existe = true;
                 break;
            }
        }
        if(!existe) {
            subfamilias.add(psf);
        }
    }
}