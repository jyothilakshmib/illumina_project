public with sharing class ZipCodeService {

    // Custom exception class
    public class CustomException extends Exception {}

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getZipCodeData(String zipCode, String countryCode) {
        String apiUrl = 'http://api.zippopotam.us/' + countryCode + '/' + zipCode;
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(apiUrl);
        request.setMethod('GET');
        
        try {
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> places = (List<Object>) responseData.get('places');
                
                Map<String, Object> formattedData = new Map<String, Object>();
                if (responseData.containsKey('country')) {
                    String country = (String) responseData.get('country');
                    formattedData.put('country', country);
                    
                    if (country != null && country != 'United States') {
                        // Format non-US data
                        List<Map<String, Object>> nonUSData = formatNonUSResponse(responseData);
                        saveNonUSData(nonUSData); // Corrected the parameter type here
                        formattedData.put('places', nonUSData);
                    } else {
                        // Format US data
                        Map<String, Object> usData = formatUSResponse(responseData);
                        formattedData.put('places', usData);
                    }
                }
                
                return formattedData;  // Ensure we return a map in all cases
            } else {
                throw new CustomException('Failed to fetch zip code data. Status Code: ' + response.getStatusCode());
            }
        } catch (Exception e) {
            throw new CustomException('Error fetching zip code data: ' + e.getMessage());
        }
    }    

    // Helper method to format the response for US data
    private static Map<String, Object> formatUSResponse(Map<String, Object> responseData) {
        Map<String, Object> result = new Map<String, Object>();
        
        List<Object> places = (List<Object>) responseData.get('places');
        if (places != null && !places.isEmpty()) {
            Map<String, Object> placeDetails = (Map<String, Object>) places[0];
            result.put('placeName', placeDetails.get('place name'));
            result.put('state', placeDetails.get('state'));
            result.put('latitude', placeDetails.get('latitude'));
            result.put('longitude', placeDetails.get('longitude'));
        }

        return result;
    }

    // Helper method to format the response for non-US data
    private static List<Map<String, Object>> formatNonUSResponse(Map<String, Object> responseData) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        
        List<Object> places = (List<Object>) responseData.get('places');
        
        if (places != null && !places.isEmpty()) {
            for (Object placeObj : places) {
                Map<String, Object> placeDetails = (Map<String, Object>) placeObj;
                
                Map<String, Object> formattedData = new Map<String, Object>();
                formattedData.put('placeName', placeDetails.get('place name'));
                formattedData.put('state', placeDetails.get('state'));
                formattedData.put('latitude', placeDetails.get('latitude'));
                formattedData.put('longitude', placeDetails.get('longitude'));
    
                result.add(formattedData);
            }
        }
    
        return result;
    }

    private static void saveNonUSData(List<Map<String, Object>> responseDataList) {
        List<ZipCodeData__c> recordsToInsert = new List<ZipCodeData__c>();

        // Loop through each response data map (for multiple records)
        for (Map<String, Object> responseData : responseDataList) {
            if (responseData == null || responseData.isEmpty()) {
                System.debug('⚠ Skipping empty responseData entry');
                continue;
            }
            List<Map<String, Object>> placesList = new List<Map<String, Object>>();
            if (responseData.containsKey('places')) {
                Object placesObj = responseData.get('places');
                
                if (placesObj instanceof List<Object>) {
                    placesList = (List<Map<String, Object>>) placesObj;
                } else if (placesObj instanceof Map<String, Object>) {
                    placesList.add((Map<String, Object>) placesObj);
                } else {
                    System.debug('⚠ Invalid "places" format in responseData: ' + placesObj);
                    continue;
                }
            } else {
                // Handle case where "places" is not available
                System.debug('⚠ No "places" field found in responseData');
                continue;
            }

            for (Map<String, Object> placeDetails : placesList) {
                if (placeDetails == null || placeDetails.isEmpty()) {
                    System.debug('⚠ Skipping empty placeDetails entry');
                    continue;
                }

                ZipCodeData__c newRecord = new ZipCodeData__c();

                newRecord.PlaceName__c = (String) placeDetails.get('place name');
                newRecord.State__c = (String) placeDetails.get('state');

                Object latObj = placeDetails.get('latitude');
                Object longObj = placeDetails.get('longitude');

                if (latObj != null) {
                    newRecord.Latitude__c = (latObj instanceof Decimal) ? (Decimal) latObj : Decimal.valueOf(latObj.toString());
                } else {
                    System.debug('⚠ Missing latitude for place: ' + placeDetails.get('place name'));
                }

                if (longObj != null) {
                    newRecord.Longitude__c = (longObj instanceof Decimal) ? (Decimal) longObj : Decimal.valueOf(longObj.toString());
                } else {
                    System.debug('⚠ Missing longitude for place: ' + placeDetails.get('place name'));
                }

                // Check if all required fields are set
                if (newRecord.PlaceName__c == null || newRecord.State__c == null || newRecord.Latitude__c == null || newRecord.Longitude__c == null) {
                    System.debug('⚠ Skipping incomplete record: ' + newRecord);
                    continue;
                }

                recordsToInsert.add(newRecord);
            }
        }

        if (!recordsToInsert.isEmpty()) {
            try {
                insert recordsToInsert;
            } catch (DmlException e) {
                throw e;
            }
        } else {
            System.debug('⚠ No valid records to insert.');
        }
    }
}
