public class HelperClass {

    // Helper function to fetch a user that is not the same as account owner
    public static Id getDifferentOwner(Id currentOwnerId) {
        User newOwner = [SELECT Id FROM User WHERE Id != :currentOwnerId LIMIT 1];
        return newOwner.Id;
    }
}
