public class PedidoCatalogo {
    public String numeroPedido {get; set;}
    public String token {get; set;}
    public List<ProductoPedidoCatalogo> productos {set; get;}

    public PedidoCatalogo() {
        productos = new List<ProductoPedidoCatalogo>();
    }
    
}