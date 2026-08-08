public class OrderPrototype 
{
    private String m_orderId;
    
    public OrderPrototype (String id)
    {
        m_orderId = id;
    }
    
    public PedidoDeCompra__c cloneOrder()
    {
        List<PedidoLineItem__c> orderProductsOriginal;
        List<PedidoLineItem__c> orderProductsCloned;
        PedidoDeCompra__c original;
        PedidoDeCompra__c cloned;
        
        // obtener opedido
        original = getOrder();
        System.debug('original order id[' + original.Id + ']');

        // clonar pedido
        cloned = original.clone(false, true);
        System.debug('pedido clonado');

        // obtener productos
        orderProductsOriginal = getOrderProducts(original.Id);
        System.debug('recuperando productos del pedido');

        // agregar pedido clonado
        insert cloned;
        System.debug('insertando pedido clonado');

        // clonar productos
        orderProductsCloned = cloneOrderProducts(orderProductsOriginal, cloned);
        System.debug('se clona nproductos');
        
        return cloned;
    }

    private PedidoDeCompra__c getOrder()
    {
       PedidoDeCompra__c originalOrder;
        
       originalOrder = [SELECT Id,
                               PorcentajeDepositoAFabrica__c,
                               Booking_Agente__c,
                               //Agente_DO__c,
                               Cuenta_Agente_DO__c,
                               BL__c,
                               Confirmacion_Proveedor__c,
                               diseno_aprobado__c,
                               fotos_cargue_cont__c,
                               fotos_fin_produccion__c,
                               Informe_de_Auditoria__c,
                               justificante_de_pago__c,
                               CambioDocumentsXHQ__c,
                               Certificado_de_Origen__c,
                               CertificadoOrigen__c,
                               ComisionAdministrativa__c,
                               diseno_a_fabrica__c,
                               Estado2__c,
                               ETA__c,
                               ETD__c,
                               Fecha_aprobacion_Packaging_Cliente__c,
                               FechaConfirmacionCliente__c,
                               Fecha_de_Auditoria__c,
                               Fecha_de_Carga_de_Contenedor__c,
                               Fecha_fin_de_Produccion__c,
                               Fecha_Factura__c,
                               Fecha_limite_de_aprobacion_de_Packaging__c,
                               Fecha_Maxima_Embarque__c,
                               Fecha_Minima_Embarque__c,
                               Grupaje__c,
                               Id_Sandbox__c,
                               info_a_disenadores__c,
                               InspeccionXEntrega__c,
                               Muestras__c,
                               N_de_Seal__c,
                               NroInspecciones__c,
                               NumeroDeContenedor__c,
                               Numero_de_Factura__c,
                               Numero_de_Facturas__c,
                               Numero_de_Packig_List__c,
                               Name,
                               PlazoPago__c,
                               PlazoFabricacion__c,
                               PlazoPagoFab__c,
                               Numero_de_Orden__c,
                               c_Produccion_Finalizada__c,
                               Proforma__c,
                               OwnerId,
                               Proveedor__c,
                               //Puerto_de_destino__c,
                               c_Requiere_Auditoria__c,
                               Requisitos_Especiales__c,
                               TipoDeInteresFinanciacionClient__c,
                               TipoDeInteresDepositoFabrica__c
                          FROM PedidoDeCompra__c
                         WHERE Id=:m_orderId];

       originalOrder.Name = 'Autogenerado';
       return originalOrder;
    }


    private List<PedidoLineItem__c> getOrderProducts(String orderId)
    {
        List<PedidoLineItem__c> productos = [SELECT Id, 
                                                    Name,
                                                    CBMMasterbox__c,
                                                    CostoOrigen__c,
                                                    CreatedById,
                                                    Id_Sandbox__c,
                                                    NumeroDeCajas__c,
                                                    //PedidoDeCompra__c,
                                                    PrecioDeVenta__c,
                                                    ProformaLineItem__c,
                                                    Requisitos_Especiales__c,
                                                    UnidadesPorMasterbox__c
                                               FROM PedidoLineItem__c
                                              WHERE PedidoDeCompra__c =:orderId];
        return productos;
    }


    private List<PedidoLineItem__c> cloneOrderProducts(List<PedidoLineItem__c> originalProducts, PedidoDeCompra__c pedidoCloned)
    {
        PedidoLineItem__c clonedProduct;
        List<PedidoLineItem__c> clonedProducts = new List<PedidoLineItem__c>();
        for(PedidoLineItem__c originalProduct : originalProducts)
        {
            clonedProduct = originalProduct.clone(false, true);
            clonedProduct.PedidoDeCompra__c = pedidoCloned.id;
            clonedProducts.add(clonedProduct);
        }
        
        insert clonedProducts;
        return clonedProducts;
    }

}