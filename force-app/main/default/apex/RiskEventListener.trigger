trigger RiskEventListener on RiskAlertEvent__e (after insert) {
    List<Case> casesToCreate = new List<Case>();

    for (RiskAlertEvent__e event : Trigger.new) {
        // Get the account associated with the event
        Account account = [SELECT Id, OwnerId FROM Account WHERE Id = :event.AccountId__c LIMIT 1];

        // Create a new case and assign a different owner than the Account Owner
        Case newCase = new Case(
            Subject = 'Risk Case for Account ' + account.Id,
            Description = 'This case was created because the risk level is High.',
            AccountId = account.Id,
            OwnerId = getDifferentOwner(account.OwnerId)  // Assign a different owner
        );

        casesToCreate.add(newCase);
    }

    // Insert the cases
    if (!casesToCreate.isEmpty()) {
        insert casesToCreate;
    }
}

// Helper function to return a different user as owner
public static Id getDifferentOwner(Id currentOwnerId) {
    User newOwner = [SELECT Id FROM User WHERE Id != :currentOwnerId LIMIT 1];
    return newOwner.Id;
}
