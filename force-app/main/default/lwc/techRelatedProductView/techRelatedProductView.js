import { LightningElement, api, wire } from 'lwc';
import getRelatedProducts from '@salesforce/apex/TechRelatedProductController.getRelatedProducts';

const COLUMNS = [
    { label: 'Provider Code', fieldName: 'Codigo_Proveedor__c', type: 'text' },
    { label: 'Price', fieldName: 'PrecioDeFabrica__c', type: 'currency', typeAttributes: { currencyCode: 'USD' } },
    { label: 'Supplier Name', fieldName: 'Nombre_Fabrica__c', type: 'text' }
];

export default class TechRelatedProductView extends LightningElement {
    @api recordId;
    columns = COLUMNS;
    data = [];
    error;
    
    @wire(getRelatedProducts, { recordId: '$recordId' })
    wiredProducts({ error, data }) {
        if (data) {
            this.data = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = [];
        }
    }
}
