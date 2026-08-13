import { LightningElement, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PARSER from '@salesforce/resourceUrl/papaparse';
import getProductFields from '@salesforce/apex/ProductImportWizardController.getProductFields';
import importProducts from '@salesforce/apex/ProductImportWizardController.importProducts';
import getRecordTypeIdsByDeveloperName from '@salesforce/apex/ProductImportWizardController.getRecordTypeIdsByDeveloperName';

const MAX_ROWS = 5000;
const STEPS = ['step1', 'step2', 'step3', 'step4'];

// ── Plantillas de CSV de seguimiento (Fase 2) ──────────────────────────
// Cuando la importación actual crea productos que sirven de "padre" para
// otro nivel del modelo (Producto Base → Producto de Fábrica → Opción de
// Packaging), se ofrece descargar un CSV ya listo con el Id del padre y
// las columnas típicas que hace falta llenar para el siguiente nivel.
const FOLLOWUP_TEMPLATES = [
    {
        value: 'fabrica',
        label: 'Producto de Fábrica (a partir de Productos Base)',
        recordTypeDevName: 'ProductoDeFabrica',
        parentLookupField: 'ProductoBase__c',
        extraFields: ['Fabrica__c', 'Codigo_Proveedor__c', 'PrecioDeFabrica__c', 'Incoterm__c', 'MOQ__c', 'PlazoDeFabricacion__c', 'Packaging__c']
    },
    {
        value: 'packaging',
        label: 'Opción de Packaging (a partir de Productos de Fábrica)',
        recordTypeDevName: 'OpcionDePackaging',
        parentLookupField: 'ProductoDeFabrica__c',
        extraFields: ['Packaging__c', 'PackagingPersonalizado__c', 'CostoPackaging__c']
    }
];

export default class ProductImportWizard extends LightningElement {

    // ── Estado del wizard ──────────────────────────────────────────────
    currentStep = 'step1';

    // ── Configuración de operación ─────────────────────────────────────
    operationType = 'insert';
    matchField    = '';

    // ── Datos del archivo ──────────────────────────────────────────────
    fileName    = '';
    fileContent = '';
    csvHeaders  = [];   // [{ name, sample, mappedField }]
    parsedData  = [];   // líneas crudas del CSV (sin encabezados)

    // ── Opciones de campos ─────────────────────────────────────────────
    productFieldOptions = [];
    matchFieldOptions   = [];
    fieldTypeMap        = {};   // apiName → tipo Salesforce

    // ── Estado de la importación ───────────────────────────────────────
    importResult  = null;
    showResultModal = false;
    isSuccess     = false;
    _isProcessing = false;
    papaParseLoaded = false;

    // ── CSV de seguimiento (Fase 2) ─────────────────────────────────────
    recordTypeIdsByDevName = {};
    followupTemplateValue  = FOLLOWUP_TEMPLATES[0].value;

    get followupTemplateOptions() {
        return FOLLOWUP_TEMPLATES.map(t => ({ label: t.label, value: t.value }));
    }

    get hasSuccessRecords() {
        return !!(this.importResult && this.importResult.successRecords && this.importResult.successRecords.length > 0);
    }

    handleFollowupTemplateChange(event) {
        this.followupTemplateValue = event.detail.value;
    }

    // ══ GETTERS DE PASO ═══════════════════════════════════════════════
    get isStep1() { return this.currentStep === 'step1'; }
    get isStep2() { return this.currentStep === 'step2'; }
    get isStep3() { return this.currentStep === 'step3'; }
    get isStep4() { return this.currentStep === 'step4'; }
    get isFirstStep() { return this.currentStep === 'step1'; }

    // ══ GETTERS DE OPERACIÓN ══════════════════════════════════════════
    get isUpsert() { return this.operationType === 'upsert'; }
    get isUpdate() { return this.operationType === 'update'; }

    get needsMatchField() {
        return this.operationType === 'update' || this.operationType === 'upsert';
    }

    get operationName() {
        const names = { insert: 'Insertar', update: 'Actualizar', upsert: 'Upsert' };
        return names[this.operationType] ?? this.operationType;
    }

    // ══ GETTERS DE CLASES CSS (tarjetas de operación) ════════════════
    get insertCardClass() {
        return `operation-card${this.operationType === 'insert' ? ' selected' : ''}`;
    }
    get updateCardClass() {
        return `operation-card${this.operationType === 'update' ? ' selected' : ''}`;
    }
    get upsertCardClass() {
        return `operation-card${this.operationType === 'upsert' ? ' selected' : ''}`;
    }

    // ══ GETTERS DE NAVEGACIÓN ════════════════════════════════════════
    get nextButtonLabel() {
        return this.currentStep === 'step4' ? 'Ejecutar Importación' : 'Siguiente →';
    }

    get isNextDisabled() {
        if (this.currentStep === 'step1' && this.needsMatchField && !this.matchField) return true;
        if (this.currentStep === 'step2' && !this.fileName) return true;
        if (this.currentStep === 'step3' && this.mappedFieldCount === 0) return true;
        if (this.currentStep === 'step4' && (this._isProcessing || (this.importResult && this.isSuccess))) return true;
        return false;
    }

    // ══ GETTERS DE RESULTADO ═════════════════════════════════════════
    get mappedFieldCount() {
        return this.csvHeaders.filter(h => h.mappedField).length;
    }

    get isProcessing() { return this._isProcessing; }

    get resultBoxClass() {
        return `result-box${this.isSuccess ? ' result-box--success' : ' result-box--error'}`;
    }

    get resultIcon() {
        return this.isSuccess ? 'utility:success' : 'utility:error';
    }

    get resultTitle() {
        return this.isSuccess ? '¡Importación completada!' : 'Error en la importación';
    }

    // ══ WIRE: Campos del objeto Product2 ═════════════════════════════
    @wire(getProductFields)
    wiredFields({ error, data }) {
        if (data) {
            const sorted = data
                .map(f => ({ label: `${f.label} (${f.value})`, value: f.value }))
                .sort((a, b) => a.label.localeCompare(b.label));

            this.productFieldOptions = [{ label: '— No Mapear —', value: '' }, ...sorted];

            // Mapa tipo para conversión en executeImport
            const typeMap = {};
            data.forEach(f => { typeMap[f.value] = f.type; });
            this.fieldTypeMap = typeMap;

            // Opciones del campo de coincidencia (upsert / update)
            this.matchFieldOptions = data
                .filter(f => f.isIdLookup === 'true' || f.isExternalId === 'true' || f.value === 'Id')
                .map(f => ({ label: `${f.label} (${f.value})`, value: f.value }))
                .sort((a, b) => a.label.localeCompare(b.label));

            if (this.matchFieldOptions.length > 0) {
                this.matchField = this.matchFieldOptions[0].value;
            }
        } else if (error) {
            this.showToast('Error', 'No se pudieron cargar los campos del producto.', 'error');
        }
    }

    // ══ WIRE: Record Types de Product2 (para el CSV de seguimiento) ══
    @wire(getRecordTypeIdsByDeveloperName)
    wiredRecordTypes({ data }) {
        if (data) {
            this.recordTypeIdsByDevName = data;
        }
    }

    // ══ LIFECYCLE ════════════════════════════════════════════════════
    connectedCallback() {
        loadScript(this, PARSER)
            .then(() => { this.papaParseLoaded = true; })
            .catch(() => {
                this.showToast('Error', 'No se pudo cargar el procesador CSV (PapaParse).', 'error');
            });
    }

    // ══ HANDLERS DE STEP 1 ═══════════════════════════════════════════
    handleOperationCardClick(event) {
        this.operationType = event.currentTarget.dataset.value;
        // Si la operación ya no necesita match field, limpiar selección
        if (!this.needsMatchField) {
            this.matchField = '';
        }
    }

    handleMatchFieldChange(event) {
        this.matchField = event.detail.value;
    }

    // ══ HANDLERS DE STEP 2 ═══════════════════════════════════════════
    handleFileUpload(event) {
        const file = event.target.files[0];
        if (!file) return;

        // Validación de tamaño (10 MB)
        if (file.size > 10 * 1024 * 1024) {
            this.showToast('Archivo muy grande', 'El archivo no puede superar 10 MB.', 'warning');
            return;
        }

        this.fileName = file.name;
        const reader = new FileReader();
        reader.onload = (e) => {
            this.fileContent = e.target.result;
            this.parseCSV(this.fileContent);
        };
        // Cambiado a ISO-8859-1 (Windows-1252) para conservar acentos generados por Excel
        reader.readAsText(file, 'ISO-8859-1');
    }

    parseCSV(csvText) {
        if (!this.papaParseLoaded) {
            this.showToast('Espera', 'El procesador CSV aún se está cargando. Intenta de nuevo en unos segundos.', 'warning');
            return;
        }

        // eslint-disable-next-line no-undef
        Papa.parse(csvText, {
            header: false,
            skipEmptyLines: true,
            complete: (results) => {
                const lines = results.data;

                if (lines.length < 2) {
                    this.showToast('Archivo vacío', 'El CSV no contiene datos o solo tiene encabezados.', 'warning');
                    this.fileName = '';
                    return;
                }

                // Validación de número de registros
                if (lines.length - 1 > MAX_ROWS) {
                    this.showToast(
                        'Demasiados registros',
                        `El archivo supera el límite de ${MAX_ROWS} filas. Divídelo en partes más pequeñas.`,
                        'error'
                    );
                    this.fileName = '';
                    return;
                }

                const headers  = lines[0];
                const sampleRow = lines[1] ?? [];

                this.csvHeaders = headers.map((header, index) => {
                    const cleanHeader = header ? header.trim() : `Columna ${index + 1}`;
                    return {
                        name: cleanHeader,
                        sample: sampleRow[index] ? sampleRow[index].trim() : '',
                        mappedField: this.autoMapField(cleanHeader)
                    };
                });

                this.parsedData = lines.slice(1);
            },
            error: () => {
                this.showToast('Error', 'No se pudo leer el archivo CSV. Verifica el formato.', 'error');
                this.fileName = '';
            }
        });
    }

    // ══ HANDLERS DE STEP 3 ═══════════════════════════════════════════
    autoMapField(csvHeader) {
        const normalized = csvHeader.toLowerCase().replace(/\s+/g, '');
        const match = this.productFieldOptions.find(opt => opt.value.toLowerCase() === normalized);
        return match ? match.value : '';
    }

    handleFieldMapping(event) {
        const headerName   = event.target.name;
        const selectedField = event.target.value;
        // Spread para crear nuevo objeto → garantiza reactividad
        this.csvHeaders = this.csvHeaders.map(h =>
            h.name === headerName ? { ...h, mappedField: selectedField } : h
        );
    }

    // ══ NAVEGACIÓN ═══════════════════════════════════════════════════
    handleNext() {
        const idx = STEPS.indexOf(this.currentStep);
        if (this.currentStep === 'step4') {
            this.executeImport();
        } else {
            this.currentStep = STEPS[idx + 1];
        }
    }

    handlePrevious() {
        const idx = STEPS.indexOf(this.currentStep);
        if (idx > 0) {
            this.currentStep = STEPS[idx - 1];
        }
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('closemodal', { bubbles: true, composed: true }));
    }

    // ══ IMPORTACIÓN ══════════════════════════════════════════════════
    executeImport() {
        const productsToProcess = [];

        this.parsedData.forEach(row => {
            const product = {};
            let hasData = false;

            this.csvHeaders.forEach((header, index) => {
                if (header.mappedField && row[index] && row[index].trim() !== '') {
                    product[header.mappedField] = this.convertValue(
                        row[index].trim(),
                        this.fieldTypeMap[header.mappedField]
                    );
                    hasData = true;
                }
            });

            if (hasData) productsToProcess.push(product);
        });

        if (productsToProcess.length === 0) {
            this.showToast('Sin datos', 'No hay datos válidos para procesar. Verifica el mapeo de campos.', 'warning');
            return;
        }

        // Activar spinner y limpiar resultado anterior
        this._isProcessing = true;
        this.importResult  = null;
        this.isSuccess     = false;

        importProducts({
            jsonData:      JSON.stringify(productsToProcess),
            operationType: this.operationType,
            matchField:    this.matchField
        })
        .then(result => {
            if (result && result.successRecords) {
                result.successRecords = result.successRecords.map(rec => ({
                    ...rec,
                    recordUrl: `/lightning/r/Product2/${rec.recordId}/view`
                }));
            }
            this.importResult = result;
            this.isSuccess    = result.totalErrors === 0;
            this.showResultModal = true;
            if(this.isSuccess) {
                this.showToast('¡Éxito!', 'Importación completada exitosamente.', 'success');
            } else if (result.totalSuccess > 0) {
                this.showToast('Importación Parcial', 'Se importaron algunos registros pero hubo errores.', 'warning');
            } else {
                this.showToast('Error de Importación', 'Todos los registros fallaron.', 'error');
            }
        })
        .catch(error => {
            const msg = error?.body?.message ?? error?.message ?? 'Error desconocido en Apex.';
            this.importResult = {
                totalSuccess: 0,
                totalErrors: productsToProcess.length,
                successRecords: [],
                errorRecords: [{ rowIndex: 'Todas', errorMessage: msg }]
            };
            this.showResultModal = true;
            this.showToast('Error de Ejecución', 'Ocurrió un fallo general en Salesforce.', 'error');
        })
        .finally(() => {
            this._isProcessing = false;
        });
    }

    closeResultModal() {
        this.showResultModal = false;
        // Opcional: Reiniciar el wizard al cerrar
        this.currentStep = 'step1';
        this.fileName = '';
        this.parsedData = [];
        this.importResult = null;
    }

    /**
     * Genera y descarga un CSV "de seguimiento" con los productos recién
     * creados/actualizados exitosamente, listo para volver a subir al wizard
     * y crear el siguiente nivel del modelo (Producto de Fábrica u Opción
     * de Packaging). Incluye el Id del padre, el RecordType destino ya
     * resuelto, y columnas vacías para los campos típicos de ese nivel.
     */
    handleDownloadFollowupCsv() {
        if (!this.papaParseLoaded) {
            this.showToast('Espera', 'El procesador CSV aún se está cargando. Intenta de nuevo en unos segundos.', 'warning');
            return;
        }
        if (!this.hasSuccessRecords) {
            this.showToast('Sin registros', 'No hay registros exitosos para generar el CSV de seguimiento.', 'warning');
            return;
        }

        const template = FOLLOWUP_TEMPLATES.find(t => t.value === this.followupTemplateValue);
        if (!template) return;

        const recordTypeId = this.recordTypeIdsByDevName[template.recordTypeDevName] || '';
        if (!recordTypeId) {
            this.showToast(
                'Record Type no encontrado',
                `No se encontró el Record Type "${template.recordTypeDevName}" en Product2. Verifica la configuración.`,
                'error'
            );
            return;
        }

        const header = [
            template.parentLookupField,
            'Name',
            'RecordTypeId',
            'Referencia_Producto_Origen',
            ...template.extraFields
        ];

        const rows = this.importResult.successRecords.map(rec => {
            const row = [rec.recordId, rec.recordName || '', recordTypeId, rec.recordName || ''];
            template.extraFields.forEach(() => row.push(''));
            return row;
        });

        // eslint-disable-next-line no-undef
        // \uFEFF es el BOM (Byte Order Mark) de UTF-8. Obliga a Excel a reconocer los acentos al abrir.
        const csvContent = '\uFEFF' + Papa.unparse([header, ...rows]);
        // Lightning Web Security intercepta Blob/URL.createObjectURL y rechaza
        // el MIME type aunque sea válido ("Unsupported MIME type"). Se evita
        // por completo usando una URI de datos directamente en el href.
        const dataUri = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent);
        const link = document.createElement('a');
        const timestamp = new Date().toISOString().slice(0, 19).replace(/[:T]/g, '-');
        link.href = dataUri;
        link.download = `seguimiento_${template.value}_${timestamp}.csv`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        this.showToast(
            'CSV generado',
            `Descarga lista con ${rows.length} fila(s). Llena las columnas vacías y vuelve a subirlo con la operación "Insertar".`,
            'success'
        );
    }

    /**
     * Convierte el valor del CSV al tipo nativo de Salesforce.
     * Evita que Apex falle al deserializar booleans, fechas y números enviados como String.
     */
    convertValue(value, fieldType) {
        if (!value || !fieldType) return value;
        const type = fieldType.toUpperCase();

        // Booleanos
        if (type === 'BOOLEAN') {
            return value.toLowerCase() === 'true' || value === '1';
        }

        // Fechas: dd/MM/yyyy o dd-MM-yyyy → yyyy-MM-dd
        if (type === 'DATE') {
            const m = value.match(/^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})$/);
            if (m) {
                const [, day, month, year] = m;
                return `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
            }
            return value;
        }

        // Fecha-Hora
        if (type === 'DATETIME') {
            const m = value.match(/^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})(\s+(.*))?$/);
            if (m) {
                const [, day, month, year, , time] = m;
                const iso = `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`;
                return time ? `${iso}T${time}` : `${iso}T00:00:00.000Z`;
            }
            return value;
        }

        // Números
        if (['INTEGER', 'CURRENCY', 'PERCENT', 'DOUBLE'].includes(type)) {
            const num = parseFloat(value.replace(',', '.'));
            return isNaN(num) ? value : num;
        }

        return value;
    }

    // ══ UTILIDADES ═══════════════════════════════════════════════════
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
