import { LightningElement, api, wire, track } from 'lwc';
import getRelatedProducts from '@salesforce/apex/TechRelatedProductController.getRelatedProducts';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    { label: 'Provider Code', fieldName: 'Codigo_Proveedor__c', type: 'text' },
    { label: 'Supplier Name', fieldName: 'Nombre_Fabrica__c', type: 'text', editable: true },
    { label: 'Status', fieldName: 'Estatus__c', type: 'text' },
    { label: 'Active (Primary)', fieldName: 'IsActive', type: 'boolean', editable: true },
    { label: 'Price', fieldName: 'PrecioDeFabrica__c', type: 'currency', editable: true, typeAttributes: { currencyCode: 'USD' } }
];

export default class TechRelatedProductView extends LightningElement {
    @api recordId;
    columns = COLUMNS;
    @track data = [];
    error;
    @track draftValues = [];
    wiredProductsResult;
    
    @wire(getRelatedProducts, { recordId: '$recordId' })
    wiredProducts(result) {
        this.wiredProductsResult = result;
        const { error, data } = result;
        if (data) {
            this.data = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = [];
        }
    }

    async handleSave(event) {
        const updatedFields = event.detail.draftValues;

        const recordInputs = updatedFields.map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });

        const promises = recordInputs.map(recordInput => updateRecord(recordInput));

        try {
            await Promise.all(promises);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Éxito',
                    message: 'Fábricas actualizadas correctamente',
                    variant: 'success'
                })
            );
            this.draftValues = [];
            await refreshApex(this.wiredProductsResult);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error al actualizar',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                })
            );
        }
    }
}
