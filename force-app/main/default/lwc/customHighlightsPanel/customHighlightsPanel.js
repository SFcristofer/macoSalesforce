import { LightningElement, api } from 'lwc';

export default class CustomHighlightsPanel extends LightningElement {
    @api recordId;
    @api objectApiName;
    
    @api title = 'Detalles Destacados';
    @api iconName = 'standard:default'; 
    @api fields = ''; 

    get fieldList() {
        return this.fields ? this.fields.split(',').map(field => field.trim()) : [];
    }
}
