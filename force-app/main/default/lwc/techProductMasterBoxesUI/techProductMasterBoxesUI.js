import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Product2.Masterbox2LargoCm__c',
    'Product2.Masterbox3LargoCm__c',
    'Product2.Masterbox4LargoCm__c',
    'Product2.Masterbox5LargoCm__c',
    'Product2.Masterbox6LargoCm__c',
    'Product2.MasterboxM3__c',
    'Product2.Masterbox2M3__c',
    'Product2.Masterbox3M3__c',
    'Product2.Masterbox4M3__c',
    'Product2.Masterbox5M3__c',
    'Product2.Masterbox6M3__c'
];

export default class TechProductMasterBoxesUI extends LightningElement {
    @api recordId;
    
    @track showBox1 = true;
    @track showBox2 = false;
    @track showBox3 = false;
    @track showBox4 = false;
    @track showBox5 = false;
    @track showBox6 = false;
    
    @track activeSections = ['Box1'];
    @track totalCBM = 0.00;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            // Verificar si la Caja 2 tiene datos
            if (data.fields.Masterbox2LargoCm__c && data.fields.Masterbox2LargoCm__c.value) {
                this.showBox2 = true;
                if (!this.activeSections.includes('Box2')) this.activeSections.push('Box2');
            }
            // Verificar si la Caja 3 tiene datos
            if (data.fields.Masterbox3LargoCm__c && data.fields.Masterbox3LargoCm__c.value) {
                this.showBox3 = true;
                if (!this.activeSections.includes('Box3')) this.activeSections.push('Box3');
            }
            if (data.fields.Masterbox4LargoCm__c && data.fields.Masterbox4LargoCm__c.value) {
                this.showBox4 = true;
                if (!this.activeSections.includes('Box4')) this.activeSections.push('Box4');
            }
            if (data.fields.Masterbox5LargoCm__c && data.fields.Masterbox5LargoCm__c.value) {
                this.showBox5 = true;
                if (!this.activeSections.includes('Box5')) this.activeSections.push('Box5');
            }
            if (data.fields.Masterbox6LargoCm__c && data.fields.Masterbox6LargoCm__c.value) {
                this.showBox6 = true;
                if (!this.activeSections.includes('Box6')) this.activeSections.push('Box6');
            }
            
            // Calcular CBM inicial
            let total = 0;
            if (data.fields.MasterboxM3__c && data.fields.MasterboxM3__c.value) total += parseFloat(data.fields.MasterboxM3__c.value);
            if (data.fields.Masterbox2M3__c && data.fields.Masterbox2M3__c.value) total += parseFloat(data.fields.Masterbox2M3__c.value);
            if (data.fields.Masterbox3M3__c && data.fields.Masterbox3M3__c.value) total += parseFloat(data.fields.Masterbox3M3__c.value);
            if (data.fields.Masterbox4M3__c && data.fields.Masterbox4M3__c.value) total += parseFloat(data.fields.Masterbox4M3__c.value);
            if (data.fields.Masterbox5M3__c && data.fields.Masterbox5M3__c.value) total += parseFloat(data.fields.Masterbox5M3__c.value);
            if (data.fields.Masterbox6M3__c && data.fields.Masterbox6M3__c.value) total += parseFloat(data.fields.Masterbox6M3__c.value);
            this.totalCBM = total.toFixed(4);
        }
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
        
        // Limpiamos visualmente los campos si el usuario quisiera guardar (aunque el form no envía campos ocultos, 
        // limpiarlos asegura que la base de datos se ponga en null si hacemos override custom más adelante,
        // pero con record-edit-form estándar, al no estar en DOM, no se guardan como nulos automáticamente,
        // se ignoran. Para una implementación simple, con ocultarlo basta para la UI).
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
        // Debounce para asegurar que el DOM actualizó el valor
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

    handleSuccess(event) {
        const toastEvent = new ShowToastEvent({
            title: 'Éxito',
            message: 'Cajas Maestras guardadas correctamente.',
            variant: 'success'
        });
        this.dispatchEvent(toastEvent);
    }
}
