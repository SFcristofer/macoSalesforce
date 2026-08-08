import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class TechNewProductForm extends NavigationMixin(LightningElement) {
    @api recordId;

    get formTitle() {
        return this.recordId ? 'Editar Producto' : 'Nuevo Producto';
    }

    handleLoad(event) {
        const record = event.detail.records;
        if (record && this.recordId) {
            const fields = record[this.recordId].fields;
            if (fields) {
                if (fields.Producto2_detalle__c && fields.Producto2_detalle__c.value) this.showProduct2 = true;
                if (fields.Producto3_detalle__c && fields.Producto3_detalle__c.value) this.showProduct3 = true;
                if (fields.Producto4_detalle__c && fields.Producto4_detalle__c.value) this.showProduct4 = true;
                if (fields.Producto5_detalle__c && fields.Producto5_detalle__c.value) this.showProduct5 = true;
                if (fields.Producto6_detalle__c && fields.Producto6_detalle__c.value) this.showProduct6 = true;

                if (fields.Masterbox2_detalle__c && fields.Masterbox2_detalle__c.value) this.showBox2 = true;
                if (fields.Masterbox3_detalle__c && fields.Masterbox3_detalle__c.value) this.showBox3 = true;
                if (fields.Masterbox4_detalle__c && fields.Masterbox4_detalle__c.value) this.showBox4 = true;
                if (fields.Masterbox5_detalle__c && fields.Masterbox5_detalle__c.value) this.showBox5 = true;
                if (fields.Masterbox6_detalle__c && fields.Masterbox6_detalle__c.value) this.showBox6 = true;
            }
            setTimeout(() => {
                this.recalculateCBM();
            }, 500);
        }
    }

    @track showBox1 = true;
    @track showBox2 = false;
    @track showBox3 = false;
    @track showBox4 = false;
    @track showBox5 = false;
    @track showBox6 = false;

    @track showProduct2 = false;
    @track showProduct3 = false;
    @track showProduct4 = false;
    @track showProduct5 = false;
    @track showProduct6 = false;
    
    @track activeFormSections = [
        'Product Information', 
        'Description Information', 
        'Product (dimensions, weight and volume)', 
        'Additional product measurements (dimensions, weight and volume)', 
        'Unit Box (dimensions, weight and volume)', 
        'Masterbox (dimensions, weight and volume)', 
        'Units per container', 
        'Images (OneDrive) & Upload'
    ];

    @track totalCBM = 0.00;

    get canAddMoreProducts() {
        return !(this.showProduct2 && this.showProduct3 && this.showProduct4 && this.showProduct5 && this.showProduct6);
    }

    handleAddProduct() {
        if (!this.showProduct2) {
            this.showProduct2 = true;
        } else if (!this.showProduct3) {
            this.showProduct3 = true;
        } else if (!this.showProduct4) {
            this.showProduct4 = true;
        } else if (!this.showProduct5) {
            this.showProduct5 = true;
        } else if (!this.showProduct6) {
            this.showProduct6 = true;
        }
    }

    handleRemoveProduct2() {
        this.showProduct2 = false;
    }

    handleRemoveProduct3() {
        this.showProduct3 = false;
    }

    handleRemoveProduct4() {
        this.showProduct4 = false;
    }

    handleRemoveProduct5() {
        this.showProduct5 = false;
    }

    handleRemoveProduct6() {
        this.showProduct6 = false;
    }

    get canAddMore() {
        return !(this.showBox1 && this.showBox2 && this.showBox3 && this.showBox4 && this.showBox5 && this.showBox6);
    }

    handleAddBox() {
        if (!this.showBox2) {
            this.showBox2 = true;
            this.activeSections.push('Box2');
        } else if (!this.showBox3) {
            this.showBox3 = true;
            this.activeSections.push('Box3');
        } else if (!this.showBox4) {
            this.showBox4 = true;
            this.activeSections.push('Box4');
        } else if (!this.showBox5) {
            this.showBox5 = true;
            this.activeSections.push('Box5');
        } else if (!this.showBox6) {
            this.showBox6 = true;
            this.activeSections.push('Box6');
        }
    }

    handleRemoveBox2() {
        this.showBox2 = false;
        this.activeSections = this.activeSections.filter(sec => sec !== 'Box2');
        this.recalculateCBM();
    }

    handleRemoveBox3() {
        this.showBox3 = false;
        this.activeSections = this.activeSections.filter(sec => sec !== 'Box3');
        this.recalculateCBM();
    }

    handleRemoveBox4() {
        this.showBox4 = false;
        this.activeSections = this.activeSections.filter(sec => sec !== 'Box4');
        this.recalculateCBM();
    }

    handleRemoveBox5() {
        this.showBox5 = false;
        this.activeSections = this.activeSections.filter(sec => sec !== 'Box5');
        this.recalculateCBM();
    }

    handleRemoveBox6() {
        this.showBox6 = false;
        this.activeSections = this.activeSections.filter(sec => sec !== 'Box6');
        this.recalculateCBM();
    }

    handleCBMChange() {
        setTimeout(() => {
            this.recalculateCBM();
        }, 200);
    }

    recalculateCBM() {
        let total = 0;
        const inputs = this.template.querySelectorAll('lightning-input-field');
        inputs.forEach(input => {
            if (input.fieldName === 'MasterboxM3__c' || input.fieldName === 'Masterbox2M3__c' || input.fieldName === 'Masterbox3M3__c' || input.fieldName === 'Masterbox4M3__c' || input.fieldName === 'Masterbox5M3__c' || input.fieldName === 'Masterbox6M3__c') {
                if (input.value) {
                    total += parseFloat(input.value);
                }
            }
        });
        this.totalCBM = total.toFixed(4);
    }

    async handleSuccess(event) {
        const productId = event.detail.id;
        
        try {
            const imageMgr = this.template.querySelector('.product-images-mgr');
            if (imageMgr) {
                // Upload images and save the OneDrive link via Apex
                await imageMgr.saveImagesForRecord(productId);
            }
        } catch (e) {
            console.error('Error saving images', e);
        }

        const toastEvent = new ShowToastEvent({
            title: 'Éxito',
            message: 'Producto creado correctamente.',
            variant: 'success'
        });
        this.dispatchEvent(toastEvent);

        // Navegar al nuevo producto
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: productId,
                objectApiName: 'Product2',
                actionName: 'view'
            }
        });
    }
}
