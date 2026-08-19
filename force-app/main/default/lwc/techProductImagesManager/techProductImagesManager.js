import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveImages from '@salesforce/apex/TechProductImagesController.saveImages';
import getFolderThumbnails from '@salesforce/apex/TechOneDriveService.getFolderThumbnails';

const FIELDS = [
    'Product2.Tech_Enlace_OneDrive__c',
    'Product2.Imagen1__c',
    'Product2.Imagen2__c',
    'Product2.Imagen3__c',
    'Product2.Imagen4__c'
];

export default class TechProductImagesManager extends LightningElement {
    @api recordId;
    @api hideSaveButton = false;

    @track onedriveLink = '';
    @track image1Preview = null;
    @track image2Preview = null;
    @track image3Preview = null;
    @track image4Preview = null;
    @track onedriveThumbnails = [];
    @track isLoadingThumbnails = false;
    @track isEditMode = false;
    isLinkLocked = false;
    
    // Store files to upload
    filesToUpload = { 1: null, 2: null, 3: null, 4: null };
    
    isSaving = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            const currentLink = data.fields.Tech_Enlace_OneDrive__c?.value || '';
            if (this.onedriveLink !== currentLink) {
                this.onedriveLink = currentLink;
                if (this.onedriveLink) {
                    this.isLinkLocked = true;
                    this.loadThumbnails();
                } else {
                    this.isLinkLocked = false;
                }
            }
            // Load existing base64 images from DB into preview if available
            this.image1Preview = data.fields.Imagen1__c?.value || null;
            this.image2Preview = data.fields.Imagen2__c?.value || null;
            this.image3Preview = data.fields.Imagen3__c?.value || null;
            this.image4Preview = data.fields.Imagen4__c?.value || null;
        }
    }

    handleLinkChange(event) {
        this.onedriveLink = event.target.value;
        this.loadThumbnails();
    }

    unlockLink() {
        this.isLinkLocked = false;
    }

    toggleEditMode() {
        this.isEditMode = !this.isEditMode;
        // Si cancela edición, podríamos recargar los datos originales, 
        // pero por ahora solo ocultamos los controles.
    }

    loadThumbnails() {
        if (!this.onedriveLink) {
            this.onedriveThumbnails = [];
            return;
        }
        this.isLoadingThumbnails = true;
        getFolderThumbnails({ sharedLink: this.onedriveLink })
            .then(result => {
                this.onedriveThumbnails = result || [];
            })
            .catch(error => {
                console.error('Error fetching OneDrive thumbnails', error);
                this.onedriveThumbnails = [];
            })
            .finally(() => {
                this.isLoadingThumbnails = false;
            });
    }

    handleFileChange(event) {
        const index = event.target.dataset.index;
        const file = event.target.files[0];
        if (!file) return;

        // Preview in UI immediately
        const reader = new FileReader();
        reader.onload = (e) => {
            this[`image${index}Preview`] = e.target.result;
        };
        reader.readAsDataURL(file);

        // Store file for later processing
        this.filesToUpload[index] = file;
    }

    @api
    async saveImagesForRecord(newRecordId) {
        if (newRecordId) {
            this.recordId = newRecordId;
        }
        await this.handleSave(true);
    }

    async handleSave(hideToast = false) {
        this.isSaving = true;
        try {
            const finalImages = { 1: null, 2: null, 3: null, 4: null };

            for (let i = 1; i <= 4; i++) {
                const file = this.filesToUpload[i];
                if (file) {
                    const checkbox = this.template.querySelector(`lightning-input[data-index="${i}"][type="checkbox"]`);
                    const shouldResize = checkbox ? checkbox.checked : false;

                    if (shouldResize) {
                        finalImages[i] = await this.resizeImage(file, 2048, 0.9);
                    } else {
                        finalImages[i] = await this.fileToBase64(file);
                    }
                }
            }

            await saveImages({
                recordId: this.recordId,
                onedriveLink: this.onedriveLink,
                img1: finalImages[1],
                img2: finalImages[2],
                img3: finalImages[3],
                img4: finalImages[4]
            });

            if (hideToast !== true) {
                this.showToast('Éxito', 'Imágenes y enlace guardados correctamente', 'success');
            }
            // Clear file buffer (keep previews)
            this.filesToUpload = { 1: null, 2: null, 3: null, 4: null };
            // Volver a modo lectura
            this.isEditMode = false;
            
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
            throw error;
        } finally {
            this.isSaving = false;
        }
    }

    fileToBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result);
            reader.onerror = error => reject(error);
            reader.readAsDataURL(file);
        });
    }

    resizeImage(file, maxDimension, quality) {
        return new Promise((resolve, reject) => {
            const img = new Image();
            img.onload = () => {
                let width = img.width;
                let height = img.height;

                if (width > maxDimension || height > maxDimension) {
                    if (width > height) {
                        height = Math.round((height *= maxDimension / width));
                        width = maxDimension;
                    } else {
                        width = Math.round((width *= maxDimension / height));
                        height = maxDimension;
                    }
                }

                const canvas = document.createElement('canvas');
                canvas.width = width;
                canvas.height = height;

                const ctx = canvas.getContext('2d');
                ctx.drawImage(img, 0, 0, width, height);

                resolve(canvas.toDataURL('image/jpeg', quality));
            };
            img.onerror = (e) => reject(e);
            
            const reader = new FileReader();
            reader.onload = (e) => {
                img.src = e.target.result;
            };
            reader.readAsDataURL(file);
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title, message, variant
        }));
    }
}