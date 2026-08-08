public class LibraProductoPayload {
    public String codigo_producto {set; get;}
    public String codigo_empresa {set; get;}
    public String desc_ventas {set; get;}
    public String desc_compras {set; get;}

    public List<LibraProductoProveedorPayload> proveedores {set; get;}

    public LibraProductoPayload() {
        proveedores = new List<LibraProductoProveedorPayload>();
    }
}