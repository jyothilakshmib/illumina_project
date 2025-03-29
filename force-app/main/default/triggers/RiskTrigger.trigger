trigger RiskTrigger on Account (after update) {
    List<RiskAlertEvent__e> riskEvents = new List<RiskAlertEvent__e>();
    for (Account acc : Trigger.new) {
        // Check if Risk is set to "High"
        if (acc.Risk__c == 'High' && Trigger.oldMap.get(acc.Id).Risk__c != 'High') {
            // Create a new platform event when the Risk is set to High
            RiskAlertEvent__e newEvent = new RiskAlertEvent__e(
                RiskLevel__c = 'High',
                AccountId__c = acc.Id
            );
            riskEvents.add(newEvent);
        }
    }

    if (!riskEvents.isEmpty()) {
        Database.SaveResult[] results = EventBus.publish(riskEvents);
    }
}
