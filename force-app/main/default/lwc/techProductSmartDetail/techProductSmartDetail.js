import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

const SECTION_ICONS = {
    general: 'utility:info',
    descripcion: 'utility:description',
    fabricacion: 'utility:money',
    relaciones: 'utility:link',
    caja: 'utility:package',
    contenedor: 'utility:truck',
    productVariants: 'utility:resize',
    masterboxVariants: 'utility:package',
    images: 'utility:image'
};

const SIMPLE_SECTIONS = [
    {
        key: 'general',
        title: 'Información General',
        fields: [
            { api: 'Name', label: 'Nombre', type: 'text' },
            { api: 'ProductName__c', label: 'Nombre Comercial', type: 'text' },
            { api: 'IsActive', label: 'Activo', type: 'boolean' },
            { api: 'ProductCode', label: 'Código de Producto', type: 'text' },
            { api: 'Estatus__c', label: 'Estatus', type: 'text', editable: false },
            { api: 'Clasificacion_producto__c', label: 'Clasificación', type: 'text' },
            { api: 'Family', label: 'Familia', type: 'text' },
            { api: 'Subfamilia__c', label: 'Subfamilia', type: 'text' },
            { api: 'Clase__c', label: 'Clase', type: 'text' },
            { api: 'Marca__c', label: 'Marca', type: 'text' },
            { api: 'Color__c', label: 'Color', type: 'text' },
            { api: 'Codigo_EAN__c', label: 'Código EAN', type: 'text' },
            { api: 'Codigo_DUN_14__c', label: 'Código DUN-14', type: 'text' },
            { api: 'CodigoArancelario__c', label: 'Código Arancelario', type: 'text' },
            { api: 'Codigo_Proveedor__c', label: 'Código del Proveedor', type: 'text' },
            { api: 'CodigoDeProductoBase__c', label: 'Código Producto Base', type: 'text', editable: false },
            { api: 'Item_Cliente__c', label: 'Item del Cliente', type: 'text' },
            { api: 'Packaging__c', label: 'Packaging', type: 'text' },
            { api: 'PackagingPersonalizado__c', label: 'Packaging Personalizado', type: 'text' }
        ]
    },
    {
        key: 'descripcion',
        title: 'Descripción',
        fields: [
            { api: 'Description', label: 'Descripción', type: 'text' },
            { api: 'Material__c', label: 'Material', type: 'text' },
            { api: 'ComposicionEnPorcentaje__c', label: 'Composición (%)', type: 'text' },
            { api: 'Garantia__c', label: 'Garantía', type: 'boolean' },
            { api: 'ManualDeInstrucciones__c', label: 'Manual de Instrucciones', type: 'boolean' },
            { api: 'Listado_en_catalogo__c', label: 'Listado en Catálogo', type: 'boolean' },
            { api: 'Observaciones__c', label: 'Observaciones', type: 'text' }
        ]
    },
    {
        key: 'fabricacion',
        title: 'Fabricación y Costos',
        fields: [
            { api: 'Fabrica__c', label: 'Fábrica', type: 'reference', refField: 'Fabrica__r', refObject: 'Account' },
            { api: 'PlazoDeFabricacion__c', label: 'Plazo de Fabricación', type: 'text' },
            { api: 'Incoterm__c', label: 'Incoterm', type: 'text' },
            { api: 'Puerto__c', label: 'Puerto', type: 'text', editable: false },
            { api: 'MOQ__c', label: 'MOQ', type: 'number', unit: 'uds' },
            { api: 'PrecioDeFabrica__c', label: 'Precio de Fábrica', type: 'currency' },
            { api: 'Precio_Vigente__c', label: 'Precio Vigente', type: 'boolean' },
            { api: 'CostoPackaging__c', label: 'Costo de Packaging', type: 'currency' },
            { api: 'CostoImportacionUnidad__c', label: 'Costo de Importación / Unidad', type: 'currency', editable: false },
            { api: 'CostoTotal2__c', label: 'Costo Total', type: 'currency', editable: false },
            { api: 'CostoDeFabricaHijo__c', label: 'Costo de Fábrica (Hijo)', type: 'currency', editable: false },
            { api: 'Fecha_revision_costo__c', label: 'Fecha de Revisión de Costo', type: 'text' }
        ]
    },
    {
        key: 'relaciones',
        title: 'Relaciones',
        fields: [
            { api: 'ProductoBase__c', label: 'Producto Base', type: 'reference', refField: 'ProductoBase__r', refObject: 'Product2' },
            { api: 'ProductoDeFabrica__c', label: 'Producto de Fábrica', type: 'reference', refField: 'ProductoDeFabrica__r', refObject: 'Product2' },
            { api: 'Similar_a__c', label: 'Similar a', type: 'reference', refField: 'Similar_a__r', refObject: 'Product2' }
        ]
    },
    {
        key: 'caja',
        title: 'Caja Unitaria',
        fields: [
            { api: 'CajaLargoCm__c', label: 'Largo', type: 'number', unit: 'cm' },
            { api: 'CajaAnchoCm__c', label: 'Ancho', type: 'number', unit: 'cm' },
            { api: 'CajaAltoCm__c', label: 'Alto', type: 'number', unit: 'cm' },
            { api: 'CajaM3__c', label: 'Volumen', type: 'number', unit: 'm³' },
            { api: 'CajaPesoKg__c', label: 'Peso', type: 'number', unit: 'kg' }
        ]
    },
    {
        key: 'contenedor',
        title: 'Unidades por Contenedor',
        fields: [
            { api: 'UnidadesHQ__c', label: 'Unidades HQ', type: 'number', unit: 'uds' },
            { api: 'UnidadesContainer40__c', label: "Unidades Contenedor 40'", type: 'number', unit: 'uds' },
            { api: 'UnidadesContainer20__c', label: "Unidades Contenedor 20'", type: 'number', unit: 'uds' },
            { api: 'UnidadesContainer40HQCalculado__c', label: "Contenedor 40' HQ (calculado)", type: 'number', unit: 'uds', editable: false },
            { api: 'UnidadesContainer40Calculado__c', label: "Contenedor 40' (calculado)", type: 'number', unit: 'uds', editable: false },
            { api: 'UnidadesContainer20Calculado__c', label: "Contenedor 20' (calculado)", type: 'number', unit: 'uds', editable: false }
        ]
    }
];

const PRODUCT_VARIANTS = [
    { index: 1, title: 'Producto (Principal)', detalle: 'Producto_detalle__c', largo: 'ProductoLargoCm__c', ancho: 'ProductoAnchoCm__c', alto: 'ProductoAltoCm__c', diametro: 'ProductoDiametroCm__c', m3: 'ProductoM3__c', peso: 'ProductoPesoKg__c', pesoBruto: 'G_W_del__c' },
    { index: 2, title: 'Producto 2', detalle: 'Producto2_detalle__c', largo: 'Producto2LargoCm__c', ancho: 'Producto2AnchoCm__c', alto: 'Producto2AltoCm__c', diametro: 'Producto2DiametroCm__c', m3: 'Producto2M3__c', peso: 'Producto2PesoKg__c', pesoBruto: 'Producto2PesoBruto__c' },
    { index: 3, title: 'Producto 3', detalle: 'Producto3_detalle__c', largo: 'Producto3LargoCm__c', ancho: 'Producto3AnchoCm__c', alto: 'Producto3AltoCm__c', diametro: 'Producto3DiametroCm__c', m3: 'Producto3M3__c', peso: 'Producto3PesoKg__c', pesoBruto: 'Producto3PesoBruto__c' },
    { index: 4, title: 'Producto 4', detalle: 'Producto4_detalle__c', largo: 'Producto4LargoCm__c', ancho: 'Producto4AnchoCm__c', alto: 'Producto4AltoCm__c', diametro: 'Producto4DiametroCm__c', m3: 'Producto4M3__c', peso: 'Producto4PesoKg__c', pesoBruto: 'Producto4PesoBruto__c' },
    { index: 5, title: 'Producto 5', detalle: 'Producto5_detalle__c', largo: 'Producto5LargoCm__c', ancho: 'Producto5AnchoCm__c', alto: 'Producto5AltoCm__c', diametro: 'Producto5DiametroCm__c', m3: 'Producto5M3__c', peso: 'Producto5PesoKg__c', pesoBruto: 'Producto5PesoBruto__c' },
    { index: 6, title: 'Producto 6', detalle: 'Producto6_detalle__c', largo: 'Producto6LargoCm__c', ancho: 'Producto6AnchoCm__c', alto: 'Producto6AltoCm__c', diametro: 'Producto6DiametroCm__c', m3: 'Producto6M3__c', peso: 'Producto6PesoKg__c', pesoBruto: 'Producto6PesoBruto__c' }
];

const MASTERBOX_VARIANTS = [
    { index: 1, title: 'Master Box 1 (Principal)', detalle: 'Masterbox1_detalle__c', largo: 'MasterboxLargoCm__c', ancho: 'MasterboxAnchoCm__c', alto: 'MasterboxAltoCm__c', m3: 'MasterboxM3__c', peso: 'MasterboxPesoKg__c', unidades: 'UnidadesPorMasterBox__c' },
    { index: 2, title: 'Master Box 2', detalle: 'Masterbox2_detalle__c', largo: 'Masterbox2LargoCm__c', ancho: 'Masterbox2AnchoCm__c', alto: 'Masterbox2AltoCm__c', m3: 'Masterbox2M3__c', peso: 'Masterbox2PesoKg__c', unidades: 'Unidades_por__c' },
    { index: 3, title: 'Master Box 3', detalle: 'Masterbox3_detalle__c', largo: 'Masterbox3LargoCm__c', ancho: 'Masterbox3AnchoCm__c', alto: 'Masterbox3AltoCm__c', m3: 'Masterbox3M3__c', peso: 'Masterbox3PesoKg__c', unidades: 'Units_per_Master_Box_3__c' },
    { index: 4, title: 'Master Box 4', detalle: 'Masterbox4_detalle__c', largo: 'Masterbox4LargoCm__c', ancho: 'Masterbox4AnchoCm__c', alto: 'Masterbox4AltoCm__c', m3: 'Masterbox4M3__c', peso: 'Masterbox4PesoKg__c', unidades: 'Units_per_Master_Box_4__c' },
    { index: 5, title: 'Master Box 5', detalle: 'Masterbox5_detalle__c', largo: 'Masterbox5LargoCm__c', ancho: 'Masterbox5AnchoCm__c', alto: 'Masterbox5AltoCm__c', m3: 'Masterbox5M3__c', peso: 'Masterbox5PesoKg__c', unidades: 'Units_per_Master_Box_5__c' },
    { index: 6, title: 'Master Box 6', detalle: 'Masterbox6_detalle__c', largo: 'Masterbox6LargoCm__c', ancho: 'Masterbox6AnchoCm__c', alto: 'Masterbox6AltoCm__c', m3: 'Masterbox6M3__c', peso: 'Masterbox6PesoKg__c', unidades: 'Units_per_Master_Box_6__c' }
];

const IMAGE_FIELDS = ['Imagen1__c', 'Imagen2__c', 'Imagen3__c', 'Imagen4__c'];

function collectFieldRefs() {
    const refs = new Set(['Product2.RecordTypeId']);
    SIMPLE_SECTIONS.forEach((section) => {
        section.fields.forEach((f) => {
            refs.add(`Product2.${f.api}`);
            if (f.type === 'reference' && f.refField) {
                refs.add(`Product2.${f.refField}.Name`);
            }
        });
    });
    PRODUCT_VARIANTS.forEach((v) => {
        ['detalle', 'largo', 'ancho', 'alto', 'diametro', 'm3', 'peso', 'pesoBruto'].forEach((prop) => {
            if (v[prop]) refs.add(`Product2.${v[prop]}`);
        });
    });
    MASTERBOX_VARIANTS.forEach((v) => {
        ['detalle', 'largo', 'ancho', 'alto', 'm3', 'peso', 'unidades'].forEach((prop) => {
            if (v[prop]) refs.add(`Product2.${v[prop]}`);
        });
    });
    IMAGE_FIELDS.forEach((f) => refs.add(`Product2.${f}`));
    return Array.from(refs);
}

const FIELDS = collectFieldRefs();

function isEmpty(type, value) {
    if (value === null || value === undefined) return true;
    if (type === 'text') return String(value).trim() === '';
    if (type === 'number' || type === 'currency') return Number(value) === 0;
    return false;
}

function formatValue(type, value, unit) {
    if (type === 'boolean') return value ? 'Sí' : 'No';
    if (type === 'currency') return `$${Number(value).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    if (type === 'number') {
        const formatted = Number(value).toLocaleString('en-US', { maximumFractionDigits: 4 });
        return unit ? `${formatted} ${unit}` : formatted;
    }
    return value;
}

export default class TechProductSmartDetail extends NavigationMixin(LightningElement) {
    @api recordId;

    record;
    error;
    editingKey = null;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ data, error }) {
        if (data) {
            this.record = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.record = undefined;
        }
    }

    readField(apiName) {
        const fieldData = this.record?.fields?.[apiName];
        return fieldData ? fieldData.value : undefined;
    }

    readReference(refField) {
        const fieldData = this.record?.fields?.[refField];
        const nested = fieldData?.value?.fields?.Name;
        return nested ? nested.value : undefined;
    }

    buildFieldEntries(fieldDefs) {
        const entries = [];
        fieldDefs.forEach((def) => {
            const rawValue = def.type === 'reference' ? this.readReference(def.refField) : this.readField(def.api);
            const emptyCheckType = def.type === 'reference' ? 'text' : def.type;
            if (!isEmpty(emptyCheckType, rawValue)) {
                const key = def.api;
                const isEditing = this.editingKey === key;
                entries.push({
                    key,
                    label: def.label,
                    displayValue: def.type === 'reference' ? rawValue : formatValue(def.type, rawValue, def.unit),
                    isReference: def.type === 'reference',
                    refId: def.type === 'reference' ? this.readField(def.api) : null,
                    refObject: def.refObject || null,
                    editable: def.editable !== false,
                    isEditing,
                    itemClass: isEditing ? 'tech-field-item is-editing' : 'tech-field-item'
                });
            }
        });
        return entries;
    }

    get sections() {
        if (!this.record) return [];
        return SIMPLE_SECTIONS.map((section) => {
            const fields = this.buildFieldEntries(section.fields);
            return {
                key: section.key,
                title: section.title,
                icon: SECTION_ICONS[section.key],
                fields,
                count: fields.length,
                visible: fields.length > 0
            };
        }).filter((s) => s.visible);
    }

    buildVariantEntries(variant, dimFieldDefs) {
        const fields = this.buildFieldEntries(dimFieldDefs);
        return { key: `v-${variant.index}`, title: variant.title, fields, m3Raw: variant.m3 ? this.readField(variant.m3) : null };
    }

    get productVariants() {
        if (!this.record) return [];
        return PRODUCT_VARIANTS.map((v) => {
            const defs = [
                { api: v.detalle, label: 'Detalle', type: 'text' },
                { api: v.largo, label: 'Largo', type: 'number', unit: 'cm' },
                { api: v.ancho, label: 'Ancho', type: 'number', unit: 'cm' },
                { api: v.alto, label: 'Alto', type: 'number', unit: 'cm' },
                { api: v.diametro, label: 'Diámetro', type: 'number', unit: 'cm' },
                { api: v.m3, label: 'Volumen', type: 'number', unit: 'm³' },
                { api: v.peso, label: 'Peso', type: 'number', unit: 'kg' },
                { api: v.pesoBruto, label: 'Peso Bruto', type: 'number', unit: 'kg' }
            ];
            return this.buildVariantEntries(v, defs);
        }).filter((v) => v.fields.length > 0);
    }

    get masterboxVariants() {
        if (!this.record) return [];
        return MASTERBOX_VARIANTS.map((v) => {
            const defs = [
                { api: v.detalle, label: 'Detalle', type: 'text' },
                { api: v.largo, label: 'Largo', type: 'number', unit: 'cm' },
                { api: v.ancho, label: 'Ancho', type: 'number', unit: 'cm' },
                { api: v.alto, label: 'Alto', type: 'number', unit: 'cm' },
                { api: v.m3, label: 'Volumen', type: 'number', unit: 'm³' },
                { api: v.peso, label: 'Peso', type: 'number', unit: 'kg' },
                { api: v.unidades, label: 'Unidades por Master Box', type: 'number', unit: 'uds' }
            ];
            return this.buildVariantEntries(v, defs);
        }).filter((v) => v.fields.length > 0);
    }

    get hasProductVariants() {
        return this.productVariants.length > 0;
    }

    get hasMasterboxVariants() {
        return this.masterboxVariants.length > 0;
    }

    get productVariantsBadge() {
        return `${this.productVariants.length} de ${PRODUCT_VARIANTS.length}`;
    }

    get masterboxVariantsBadge() {
        return `${this.masterboxVariants.length} de ${MASTERBOX_VARIANTS.length}`;
    }

    get images() {
        if (!this.record) return [];
        return IMAGE_FIELDS.map((api, i) => ({ key: api, index: i + 1, url: this.readField(api) })).filter((img) => img.url && String(img.url).trim() !== '');
    }

    get hasImages() {
        return this.images.length > 0;
    }

    get imagesBadge() {
        return `${this.images.length} de ${IMAGE_FIELDS.length}`;
    }

    get totalCBM() {
        const total = this.masterboxVariants.reduce((sum, v) => sum + (v.m3Raw ? Number(v.m3Raw) : 0), 0);
        return total.toFixed(4);
    }

    get hasVolumeBadge() {
        return this.hasMasterboxVariants && Number(this.totalCBM) > 0;
    }

    get recordName() {
        return this.readField('Name') || 'Producto';
    }

    get productCode() {
        return this.readField('ProductCode');
    }

    get recordTypeLabel() {
        return this.record?.recordTypeInfo?.name;
    }

    get isActive() {
        return this.readField('IsActive') === true;
    }

    get statusBadgeClass() {
        return this.isActive ? 'slds-badge slds-theme_success tech-status-badge' : 'slds-badge tech-status-badge tech-status-inactive';
    }

    get statusLabel() {
        return this.isActive ? 'Activo' : 'Inactivo';
    }

    get displayPrice() {
        const value = this.readField('PrecioDeFabrica__c');
        return value ? formatValue('currency', value) : null;
    }

    get quickStats() {
        const stats = [{ key: 'estado', label: 'Estado', value: this.statusLabel }];
        if (this.displayPrice) {
            stats.push({ key: 'precio', label: 'Precio de Fábrica', value: this.displayPrice });
        }
        if (this.hasVolumeBadge) {
            stats.push({ key: 'cbm', label: 'Volumen Total', value: `${this.totalCBM} m³` });
        }
        if (this.hasMasterboxVariants) {
            stats.push({ key: 'masterboxes', label: 'Masterboxes', value: this.masterboxVariantsBadge });
        }
        if (this.hasProductVariants && this.productVariants.length > 1) {
            stats.push({ key: 'variantes', label: 'Variantes de Producto', value: this.productVariantsBadge });
        }
        return stats;
    }

    get activeSectionNames() {
        const names = this.sections.map((s) => s.key);
        if (this.hasProductVariants) names.push('productVariants');
        if (this.hasMasterboxVariants) names.push('masterboxVariants');
        if (this.hasImages) names.push('images');
        return names;
    }

    get productVariantsIcon() {
        return SECTION_ICONS.productVariants;
    }

    get masterboxVariantsIcon() {
        return SECTION_ICONS.masterboxVariants;
    }

    get imagesIcon() {
        return SECTION_ICONS.images;
    }

    get hasData() {
        return this.sections.length > 0 || this.hasProductVariants || this.hasMasterboxVariants || this.hasImages;
    }

    startInlineEdit(event) {
        this.editingKey = event.currentTarget.dataset.field;
    }

    cancelInlineEdit() {
        this.editingKey = null;
    }

    saveInlineEdit() {
        const form = this.template.querySelector('lightning-record-edit-form.tech-inline-form');
        if (form) form.submit();
    }

    handleInlineSuccess() {
        this.editingKey = null;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Guardado',
                message: 'El campo se actualizó correctamente.',
                variant: 'success'
            })
        );
    }

    handleInlineError(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error al guardar',
                message: event.detail?.message || event.detail?.detail || 'Revisa el valor ingresado.',
                variant: 'error'
            })
        );
    }

    handleNavigate(event) {
        event.preventDefault();
        const { id, object } = event.currentTarget.dataset;
        if (!id || !object) return;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
                objectApiName: object,
                actionName: 'view'
            }
        });
    }
}
