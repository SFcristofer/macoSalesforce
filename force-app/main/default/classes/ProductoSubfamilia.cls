public class ProductoSubfamilia {
    public String clave {set; get;}
    public String descripcion {set; get;}
    public String imagen {set; get;}
    public List<ProductoClase> clases {set; get;}    

    public ProductoSubfamilia() {
        clases = new List<ProductoClase>();
    }
}