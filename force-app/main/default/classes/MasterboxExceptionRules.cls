/**
 * Punto de extension para el calculo de cajas (unidades -> cajas) del contenedor / proforma.
 * Hoy (2026-08-15) Pacific confirmo que no existen excepciones al calculo estandar:
 *   cajas = CEILING(unidadesSolicitadas / unidadesPorMasterboxCaja1) * totalDeMasterboxDelProducto
 * Este metodo se deja como gancho vacio para cuando aparezca un caso especial que la formula
 * estandar no pueda resolver. Mientras retorne null, ContainerAddItems usa siempre la formula
 * estandar.
 */
public class MasterboxExceptionRules {
    public static Decimal overrideBoxCount(Product2 prod, Decimal requestedUnits) {
        return null; // futuras excepciones se agregan aqui
    }
}