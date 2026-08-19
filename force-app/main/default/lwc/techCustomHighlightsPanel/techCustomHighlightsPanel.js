import { LightningElement, api } from 'lwc';

export default class TechCustomHighlightsPanel extends LightningElement {
    @api recordId;
    @api objectApiName;
    
    @api title = 'Tech Detalles Destacados';
    @api iconName = 'standard:default'; 
    @api fields = ''; 

    get fieldList() {
        return this.fields ? this.fields.split(',').map(field => field.trim()) : [];
    }
}