trigger RiskAlertEventTrigger on RiskAlertEvent__e (after insert) {
    List<Case> casesToCreate = new List<Case>();

    for (RiskAlertEvent__e event : Trigger.New) {
        Case newCase = new Case(
            Subject = 'Risk Level Alert: ' + event.RiskLevel__c,
            Description = 'Risk level has been set to ' + event.RiskLevel__c,
            AccountId = event.AccountId__c, // Link the case to the related Account
            OwnerId = 'USER_ID' // Set a user other than the account owner as the case owner
        );
        casesToCreate.add(newCase);
    }

    // Insert the cases
    insert casesToCreate;
}
