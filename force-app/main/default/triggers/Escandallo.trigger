/**
*   Whenever the Escandallo is modified, updates Import Cost and all Pricebook Entries for all products.
*   Version 1.0
*   @author lcosta@infolastic.com
*/
trigger Escandallo on Escandallo__c (after update) {
    ActualizarPrecioProductoController appc = new ActualizarPrecioProductoController();
    appc.updatePrice();
}