import { LightningElement, track } from 'lwc';
import MUI_CSS from '@salesforce/resourceUrl/MUI';
import getZipCodeData from '@salesforce/apex/ZipCodeService.getZipCodeData';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class ZipCodeInput extends LightningElement {
    @track zipCode = '';
    @track countryCode = '';
    @track apiResponse = null;
    @track errorMessage = '';
    @track isUsTabActive = true; // Default to US Data tab
    @track isNonUsTabActive = false;
    @track nonUsData = [];

    connectedCallback() {
        // Load MUI CSS
        loadStyle(this, MUI_CSS).then(() => {
            const link = document.createElement('link');
            link.rel = 'stylesheet';
            link.href = 'https://cdn.jsdelivr.net/npm/@mui/material@5.2.8/dist/material.min.css';
            document.head.appendChild(link);
        }).catch(error => {
           throw new Error(error);
           
        });
    }

    // Dropdown options for country selection
    countryOptions = [
        { label: 'United States', value: 'us' },
        { label: 'Mexico', value: 'mx' },
        { label: 'Canada', value: 'ca' }
    ];

    handleZipCodeChange(event) {
        this.zipCode = event.target.value;
    }

    handleCountryChange(event) {
        this.countryCode = event.detail.value; // Correct way to get value from lightning-combobox
    }

    handleButtonClick() {
        if (!this.zipCode) {
            this.errorMessage = 'Please enter a valid zip code.';
            this.apiResponse = null;
            return;
        }

        getZipCodeData({ zipCode: this.zipCode, countryCode: this.countryCode })
        .then(data => {
            if (data.country === 'United States') {
                this.apiResponse = data;
                this.nonUsData = {country: "No data", places:{latitude: "No data", longitude: "No data", placeName: "No data", state : "No data"}};
                this.isUsTabActive = true;
                this.isNonUsTabActive = false;
            } else {
                this.nonUsData = { ...data, places: data.places[0] };
                this.apiResponse = {country: "No data", places:{latitude: "No data", longitude: "No data", placeName: "No data", state : "No data"}};
                this.isUsTabActive = false;
                this.isNonUsTabActive = true;
            }
            console.log("<><>data<><>", data)
        })
        .catch(error => {
            this.errorMessage = 'Error fetching zip code data';
            this.nonUsData = {country: "API Error", places:{latitude: "API Error", longitude: "API Error", placeName: "API Error", state : "API Error"}};
            this.apiResponse = {country: "API Error", places:{latitude: "API Error", longitude: "API Error", placeName: "API Error", state : "API Error"}};
            console.error(error);
        });
    }
    
    handleTabClick(event) {
        const selectedTab = event.target.dataset.tab;
        this.isUsTabActive = selectedTab === 'usData';
        this.isNonUsTabActive = selectedTab === 'nonUsData';
    }

    get usTabClass() {
        return this.isUsTabActive ? 'mui-btn mui-btn--primary' : 'mui-btn';
    }

    get nonUsTabClass() {
        return this.isNonUsTabActive ? 'mui-btn mui-btn--primary' : 'mui-btn';
    }
}