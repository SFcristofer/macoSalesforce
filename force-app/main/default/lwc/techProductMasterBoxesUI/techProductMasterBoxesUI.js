import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

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
    'Product2.Masterbox6M3__c',
    'Product2.Total_Masterbox_Count__c'
];

// Campos que componen cada Master Box 2-6 (se limpian al eliminar la caja)
const BOX_FIELDS = {
    2: ['Masterbox2_detalle__c', 'Masterbox2LargoCm__c', 'Masterbox2AnchoCm__c', 'Masterbox2AltoCm__c', 'Masterbox2PesoKg__c', 'Masterbox2M3__c', 'Units_per_Master_Box_2__c'],
    3: ['Masterbox3_detalle__c', 'Masterbox3LargoCm__c', 'Masterbox3AnchoCm__c', 'Masterbox3AltoCm__c', 'Masterbox3PesoKg__c', 'Masterbox3M3__c', 'Units_per_Master_Box_3__c'],
    4: ['Masterbox4_detalle__c', 'Masterbox4LargoCm__c', 'Masterbox4AnchoCm__c', 'Masterbox4AltoCm__c', 'Masterbox4PesoKg__c', 'Masterbox4M3__c', 'Units_per_Master_Box_4__c'],
    5: ['Masterbox5_detalle__c', 'Masterbox5LargoCm__c', 'Masterbox5AnchoCm__c', 'Masterbox5AltoCm__c', 'Masterbox5PesoKg__c', 'Masterbox5M3__c', 'Units_per_Master_Box_5__c'],
    6: ['Masterbox6_detalle__c', 'Masterbox6LargoCm__c', 'Masterbox6AnchoCm__c', 'Masterbox6AltoCm__c', 'Masterbox6PesoKg__c', 'Masterbox6M3__c', 'Units_per_Master_Box_6__c']
};

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
    @track totalMasterboxCount = 1;

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

            if (data.fields.Total_Masterbox_Count__c && data.fields.Total_Masterbox_Count__c.value != null) {
                this.totalMasterboxCount = data.fields.Total_Masterbox_Count__c.value;
            }
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

    handleRemoveBox2() { this.attemptRemoveBox(2); }
    handleRemoveBox3() { this.attemptRemoveBox(3); }
    handleRemoveBox4() { this.attemptRemoveBox(4); }
    handleRemoveBox5() { this.attemptRemoveBox(5); }
    handleRemoveBox6() { this.attemptRemoveBox(6); }

    /**
     * Solo permite eliminar una Master Box si no tiene informacion capturada
     * (regla confirmada en la sesion con Pacific: si tiene datos, no se puede eliminar
     * desde aqui, hay que limpiarla primero). Si esta vacia, ademas de ocultarla en
     * pantalla se limpian sus campos en Salesforce (antes solo se ocultaba visualmente).
     */
    async attemptRemoveBox(boxNumber) {
        const fieldNames = BOX_FIELDS[boxNumber];
        const inputs = Array.from(this.template.querySelectorAll('lightning-input-field'));

        const hasData = fieldNames.some((fieldName) => {
            const input = inputs.find((i) => i.fieldName === fieldName);
            if (!input) return false;
            const value = input.value;
            return value !== null && value !== undefined && value !== '' && value !== 0;
        });

        if (hasData) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'No se puede eliminar',
                message: `La Master Box ${boxNumber} tiene información capturada. Límpiela antes de poder eliminarla.`,
                variant: 'error'
            }));
            return;
        }

        const fieldsToNull = { Id: this.recordId };
        fieldNames.forEach((fieldName) => { fieldsToNull[fieldName] = null; });

        try {
            await updateRecord({ fields: fieldsToNull });
        } catch (e) {
            // La caja ya estaba vacia; si el update falla igual la ocultamos.
        }

        this[`showBox${boxNumber}`] = false;
        this.activeSections = this.activeSections.filter((sec) => sec !== `Box${boxNumber}`);
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