import { LightningElement, api, wire, track } from 'lwc';
import { getRecordUi } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TechProductSmartDetail extends LightningElement {
    @api recordId;
    @track sections = [];
    @track activeSections = [];
    @track isEditMode = false;

    toggleEditMode() {
        this.isEditMode = !this.isEditMode;
    }

    handleSuccess(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Éxito',
                message: 'El registro ha sido actualizado correctamente.',
                variant: 'success'
            })
        );
        this.isEditMode = false;
    }

    handleError(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error al Guardar',
                message: event.detail.detail || 'Revisa los campos para asegurar que cumplen con las reglas de validación.',
                variant: 'error'
            })
        );
    }

    @wire(getRecordUi, { recordIds: '$recordId', layoutTypes: 'Full', modes: 'View' })
    wiredRecordUi({ error, data }) {
        if (data) {
            const layouts = data.layouts.Product2;
            const layoutIds = Object.keys(layouts);
            const objectInfo = data.objectInfos && data.objectInfos.Product2;
            const recordInfo = data.records && data.records[this.recordId];
            
            if (layoutIds.length > 0) {
                const layoutData = layouts[layoutIds[0]].Full.View;
                
                if (layoutData && layoutData.sections) {
                    this.sections = layoutData.sections.map((sec, index) => {
                        let fields = [];
                        
                        sec.layoutRows.forEach(row => {
                            row.layoutItems.forEach(item => {
                                item.layoutComponents.forEach(comp => {
                                    if (comp.apiName) {
                                        const apiName = comp.apiName;
                                        let isCustomLookup = false;
                                        let displayValue = '';
                                        let recordLink = '';
                                        let label = apiName;
                                        
                                        // Extraemos el Label oficial de la Metadata
                                        if (objectInfo && objectInfo.fields[apiName]) {
                                            label = objectInfo.fields[apiName].label;
                                        }

                                        // Verificamos si la UI API ya tiene el nombre traducido del ID para inyectarlo manualmente
                                        if (recordInfo && recordInfo.fields[apiName]) {
                                            const rawVal = recordInfo.fields[apiName].value;
                                            const dispVal = recordInfo.fields[apiName].displayValue;
                                            
                                            // Si el framework nos da un ID crudo pero tiene el Nombre para mostrar (dispVal), forzamos su renderizado
                                            if (rawVal && typeof rawVal === 'string' && rawVal.startsWith('00') && rawVal.length >= 15 && dispVal) {
                                                isCustomLookup = true;
                                                displayValue = dispVal;
                                                recordLink = `/${rawVal}`;
                                            }
                                        }

                                        fields.push({
                                            name: apiName,
                                            label: label,
                                            isCustomLookup: isCustomLookup,
                                            displayValue: displayValue,
                                            recordLink: recordLink,
                                            cssClass: apiName.toLowerCase().includes('recordtype') ? 'tech-no-click' : ''
                                        });
                                    }
                                });
                            });
                        });
                        
                        const heading = sec.heading || `Sección ${index}`;
                        const headingLower = heading.toLowerCase();
                        
                        const isMasterbox = headingLower.includes('masterbox') || headingLower.includes('caja');
                        const isProduct = headingLower.includes('dimension') || headingLower.includes('variante') || headingLower.includes('producto');
                        const isCard = isMasterbox || isProduct;
                        
                        let icon = '';
                        if (isMasterbox) icon = '📦 ';
                        if (isProduct) icon = '🛠️ ';

                        return {
                            id: `sec-${index}`,
                            label: heading,
                            fields: fields,
                            isCard: isCard,
                            icon: icon
                        };
                    });
                    
                    this.activeSections = this.sections.map(s => s.id);
                }
            }
        } else if (error) {
            console.error('Error fetching Layout via UI API', error);
        }
    }
}