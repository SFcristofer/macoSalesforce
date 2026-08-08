public class PedidoTransferenciaSplit {
	public String pedidoId {set; get;}
	public String pedidoName {set; get;}
	public String pedidoSociedad {set; get;}
	public String pedidoProveedor {set; get;}
    public String pedidoProveedorName {set; get;}
    
    public String bankAccountBeneficiary {set; get;}
    public String billingStreet {set; get;}
    public String billingCity {set; get;}
    public String billingState {set; get;}
    public String billingPostalCode {set; get;}
    public String billingCountry {set; get;}
    public String bankAccountNumber {set; get;}
    public String bankName {set; get;}
    public String bankAddress {set; get;}
    public String swiftCode {set; get;}

    public Decimal costoOrigen {set; get;}
    public Decimal porcentajeDepositoFabrica {set; get;}
    public Decimal montoDeposito {set; get;}

	public PedidoTransferenciaSplit() {

	}

     public Integer hashCode() {
            if (pedidoId == null) return 0;
            return pedidoId.hashCode();
     }

     public Boolean equals(Object o) {
           if (o instanceof PedidoTransferenciaSplit) {
                PedidoTransferenciaSplit other = (PedidoTransferenciaSplit)o;
                if (pedidoId == null) return other.pedidoId == null;
                return pedidoId.equals(other.pedidoId);
            }
            return false;
        }

}