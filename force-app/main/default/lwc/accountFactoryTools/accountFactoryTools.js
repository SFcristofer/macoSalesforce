import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import searchFactoryProducts from '@salesforce/apex/AccountFactoryToolsController.searchFactoryProducts';
import cloneProductApex from '@salesforce/apex/AccountFactoryToolsController.cloneProduct';
import getFactoryProductsCsv from '@salesforce/apex/AccountFactoryToolsController.getFactoryProductsCsv';
import getFactoryProductsPreview from '@salesforce/apex/AccountFactoryToolsController.getFactoryProductsPreview';
import emailFactoryProductsCsv from '@salesforce/apex/AccountFactoryToolsController.emailFactoryProductsCsv';
import previewPriceUpdates from '@salesforce/apex/AccountFactoryToolsController.previewPriceUpdates';
import applyPriceUpdatesApex from '@salesforce/apex/AccountFactoryToolsController.applyPriceUpdates';

const EXPORT_PREVIEW_COLUMNS = [
    { label: 'Producto', fieldName: 'name' },
    { label: 'Supplier Code', fieldName: 'codigoProveedor' },
    { label: 'Price', fieldName: 'price', type: 'currency' }
];

const PRICE_COLUMNS = [
    { label: 'Producto', fieldName: 'productName' },
    { label: 'Supplier Code', fieldName: 'codigoProveedor' },
    { label: 'Precio Actual', fieldName: 'currentPrice', type: 'currency' },
    { label: 'Precio Nuevo', fieldName: 'newPrice', type: 'currency' },
    { label: '% Variación', fieldName: 'pctChange', type: 'number', cellAttributes: { class: { fieldName: 'pctClass' } } },
    { label: 'Aviso', fieldName: 'warning' }
];

export default class AccountFactoryTools extends LightningElement {
    @api recordId; // Account Id

    priceColumns = PRICE_COLUMNS;
    exportPreviewColumns = EXPORT_PREVIEW_COLUMNS;
    cloneModeOptions = [
        { label: 'Clonar (cambia marca)', value: 'brand' },
        { label: 'Duplicar (cambia color)', value: 'color' }
    ];

    /* -------- Wizard: que herramienta esta usando el usuario -------- */
    @track currentStep = 'menu'; // 'menu' | 'clone' | 'export' | 'prices'

    get isMenuStep() {
        return this.currentStep === 'menu';
    }
    get isCloneStep() {
        return this.currentStep === 'clone';
    }
    get isExportStep() {
        return this.currentStep === 'export';
    }
    get isPricesStep() {
        return this.currentStep === 'prices';
    }
    get stepTitle() {
        switch (this.currentStep) {
            case 'clone':
                return 'Clonar / Duplicar Producto';
            case 'export':
                return 'Exportar Productos de la Fábrica';
            case 'prices':
                return 'Actualizar Precios';
            default:
                return 'Herramienta de Fábrica';
        }
    }

    goToStep(step) {
        this.currentStep = step;
    }
    handleGoToClone() {
        this.goToStep('clone');
    }
    handleGoToExport() {
        this.goToStep('export');
        this.exportPreviewLoading = true;
        getFactoryProductsPreview({ accountId: this.recordId })
            .then((rows) => {
                this.exportPreviewRows = rows;
            })
            .catch((error) => this.notifyError('No se pudo cargar la vista previa', error))
            .finally(() => {
                this.exportPreviewLoading = false;
            });
    }
    handleGoToPrices() {
        this.goToStep('prices');
    }
    handleBackToMenu() {
        this.goToStep('menu');
    }

    /* -------- Clonar / Duplicar -------- */
    @track searchTerm = '';
    @track productOptions = [];
    @track selectedProductId;
    @track selectedProductLabel = '';
    @track cloneMode = 'brand'; // 'brand' | 'color'
    @track newBrand = '';
    @track newColor = '';
    @track cloneLoading = false;

    /* -------- Exportar / Enviar -------- */
    @track exportLoading = false;
    @track emailLoading = false;
    @track exportPreviewRows = [];
    @track exportPreviewLoading = false;

    get hasExportPreview() {
        return this.exportPreviewRows && this.exportPreviewRows.length > 0;
    }

    /* -------- Cargar / Validar / Aplicar -------- */
    @track csvContent;
    @track selectedFileName = '';
    @track priceRows = [];
    @track validateLoading = false;
    @track applyLoading = false;

    get isBrandMode() {
        return this.cloneMode === 'brand';
    }
    get isColorMode() {
        return this.cloneMode === 'color';
    }
    get cloneDisabled() {
        return !this.selectedProductId || this.cloneLoading;
    }
    get hasPriceRows() {
        return this.priceRows && this.priceRows.length > 0;
    }
    get applyDisabled() {
        return !this.hasPriceRows || this.applyLoading;
    }
    get validateDisabled() {
        return !this.csvContent || this.validateLoading;
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        searchFactoryProducts({ accountId: this.recordId, searchTerm: this.searchTerm })
            .then((result) => {
                this.productOptions = result;
            })
            .catch((error) => this.notifyError('Error buscando productos', error));
    }

    handleSelectProduct(event) {
        const id = event.currentTarget.dataset.id;
        const found = this.productOptions.find((p) => p.productId === id);
        this.selectedProductId = id;
        this.selectedProductLabel = found ? `${found.name} (${found.productCode})` : id;
        this.productOptions = [];
        this.searchTerm = '';
    }

    handleCloneModeChange(event) {
        this.cloneMode = event.target.value;
    }
    handleNewBrandChange(event) {
        this.newBrand = event.target.value;
    }
    handleNewColorChange(event) {
        this.newColor = event.target.value;
    }

    handleClone() {
        this.cloneLoading = true;
        cloneProductApex({
            productId: this.selectedProductId,
            modifyBrand: this.isBrandMode,
            newBrand: this.newBrand,
            modifyColor: this.isColorMode,
            newColor: this.newColor
        })
            .then(() => {
                this.notifySuccess('Producto clonado correctamente');
                this.selectedProductId = undefined;
                this.selectedProductLabel = '';
                this.newBrand = '';
                this.newColor = '';
            })
            .catch((error) => this.notifyError('No se pudo clonar el producto', error))
            .finally(() => {
                this.cloneLoading = false;
            });
    }

    handleDownloadCsv() {
        this.exportLoading = true;
        getFactoryProductsCsv({ accountId: this.recordId })
            .then((csv) => {
                this.downloadCsvFile(csv, 'productos_fabrica.csv');
                this.notifySuccess('CSV descargado');
            })
            .catch((error) => this.notifyError('No se pudo generar el CSV', error))
            .finally(() => {
                this.exportLoading = false;
            });
    }

    // El link de descarga debe existir en el DOM antes del click(); si no, algunos
    // navegadores/Lightning Web Security lo ignoran sin lanzar ningun error visible.
    // Ademas, Lightning Web Security no permite crear Blob URLs con MIME type
    // 'text/csv' (lanza "Unsupported MIME type"); 'text/plain' si esta permitido y
    // el archivo igual se descarga como .csv por la extension del nombre de archivo.
    downloadCsvFile(csvContent, fileName) {
        const blob = new Blob([csvContent], { type: 'text/plain' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = fileName;
        link.style.display = 'none';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
    }

    handleSendEmail() {
        this.emailLoading = true;
        emailFactoryProductsCsv({ accountId: this.recordId })
            .then((message) => {
                this.notifySuccess(message);
            })
            .catch((error) => this.notifyError('No se pudo enviar el correo', error))
            .finally(() => {
                this.emailLoading = false;
            });
    }

    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) {
            return;
        }
        this.selectedFileName = file.name;
        const reader = new FileReader();
        reader.onload = () => {
            this.csvContent = reader.result;
        };
        reader.readAsText(file);
    }

    handleValidate() {
        if (!this.csvContent) {
            this.notifyError('Cargue un archivo CSV primero', { body: { message: '' } });
            return;
        }
        this.validateLoading = true;
        previewPriceUpdates({ csvContent: this.csvContent })
            .then((rows) => {
                this.priceRows = rows.map((r) => ({
                    ...r,
                    pctClass: r.warning ? 'slds-text-color_error slds-text-title_bold' : ''
                }));
                if (this.priceRows.length === 0) {
                    this.notifyError('El archivo no tiene filas válidas', { body: { message: '' } });
                }
            })
            .catch((error) => this.notifyError('No se pudo validar el archivo', error))
            .finally(() => {
                this.validateLoading = false;
            });
    }

    handleApply() {
        this.applyLoading = true;
        // Se manda como JSON (String) en vez de List<PriceRow> directo: pasar un tipo Apex
        // personalizado como parametro de accion desde LWC llegaba corrompido (objetos
        // vacios) por como Aura serializa los parametros - con JSON.stringify + deserialize
        // manual en Apex se evita esa capa por completo.
        const rowsJson = JSON.stringify(this.priceRows);
        applyPriceUpdatesApex({ accountId: this.recordId, rowsJson })
            .then((message) => {
                this.notifySuccess(message);
                this.priceRows = [];
                this.csvContent = undefined;
                this.selectedFileName = '';
            })
            .catch((error) => this.notifyError('No se pudo aplicar la actualización', error))
            .finally(() => {
                this.applyLoading = false;
            });
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    notifySuccess(message) {
        this.dispatchEvent(new ShowToastEvent({ title: 'Éxito', message, variant: 'success' }));
    }

    notifyError(title, error) {
        // eslint-disable-next-line no-console
        console.error(title, error);
        let message = 'Error inesperado';
        if (error) {
            if (error.body && error.body.message) {
                message = error.body.message;
            } else if (Array.isArray(error.body) && error.body.length > 0 && error.body[0].message) {
                message = error.body[0].message;
            } else if (error.message) {
                message = error.message;
            }
        }
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error' }));
    }
}