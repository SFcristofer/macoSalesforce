import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getFolderThumbnails from '@salesforce/apex/TechOneDriveService.getFolderThumbnails';

const FIELDS = ['Product2.Tech_Enlace_OneDrive__c'];

export default class TechOneDrivePreview extends LightningElement {
    @api recordId;
    @track onedriveLink = '';
    @track onedriveThumbnails = [];
    @track isLoadingThumbnails = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            const currentLink = data.fields.Tech_Enlace_OneDrive__c?.value || '';
            if (this.onedriveLink !== currentLink) {
                this.onedriveLink = currentLink;
                if (this.onedriveLink) {
                    this.loadThumbnails();
                } else {
                    this.onedriveThumbnails = [];
                }
            }
        } else if (error) {
            console.error('Error fetching Product data', error);
        }
    }

    loadThumbnails() {
        this.isLoadingThumbnails = true;
        getFolderThumbnails({ sharedLink: this.onedriveLink })
            .then(result => {
                this.onedriveThumbnails = result || [];
            })
            .catch(error => {
                console.error('ERROR ONEDRIVE PREVIEW: ', error);
                this.onedriveThumbnails = [];
            })
            .finally(() => {
                this.isLoadingThumbnails = false;
            });
    }
}
