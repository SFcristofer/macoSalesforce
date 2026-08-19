import { LightningElement, api, wire } from 'lwc';
import getOrderHistory from '@salesforce/apex/TechProductOrderHistoryController.getOrderHistory';

const COLUMNS = [
    { label: 'Order Number', fieldName: 'orderNumber', type: 'text' },
    { label: 'Supplier Name', fieldName: 'supplierName', type: 'text' },
    { label: 'Qty', fieldName: 'Quantity__c', type: 'number' },
    { label: 'Product Cost', fieldName: 'CostoOrigen__c', type: 'currency', typeAttributes: { currencyCode: 'USD', step: '0.01' } }
];

export default class TechProductOrderHistory extends LightningElement {
    @api recordId;
    columns = COLUMNS;
    data = [];
    error;

    get errorMessage() {
        return this.error ? (this.error.body?.message || this.error.message) : '';
    }

    @wire(getOrderHistory, { recordId: '$recordId' })
    wiredOrders({ error, data }) {
        if (data) {
            this.data = data.map(row => {
                return {
                    ...row,
                    orderNumber: row.PedidoDeCompra__r ? row.PedidoDeCompra__r.Name : '',
                    supplierName: row.PedidoDeCompra__r ? row.PedidoDeCompra__r.Nombre_Proveedor__c : ''
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = [];
        }
    }
}