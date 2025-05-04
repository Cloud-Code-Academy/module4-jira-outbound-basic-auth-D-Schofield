/**
 * Trigger for Jira_Issue__c to create issues in Jira
 */
trigger JiraIssueTrigger on Jira_Issue__c(after insert, after update) {
	try {
		switch on Trigger.operationType {
			when AFTER_INSERT {
				JiraTriggerHelper.processIssueAfterInsert(Trigger.new);
			}
			when AFTER_UPDATE {
				// Implement update logic when needed
                // This would handle syncing changes back to Jira
				JiraTriggerHelper.processIssueAfterUpdate(Trigger.new, Trigger.oldMap);
			}
		}
	} catch (Exception e) {
		Logger.error('Error in JiraIssueTrigger')
			.addTag('JIRA')
			.setMessage('Exception: ' + e.getMessage() + '\nStack Trace: ' + e.getStackTraceString());
		
		// Update records with error message
		List<Jira_Issue__c> issuesToUpdate = new List<Jira_Issue__c>();
		for (Jira_Issue__c issue : Trigger.new) {
			issuesToUpdate.add(new Jira_Issue__c(
				Id = issue.Id
				//Error_Message__c = 'Trigger Error: ' + e.getMessage(),
				//Last_Updated__c = Datetime.now()
			));
		}
		update issuesToUpdate;
	}
}
