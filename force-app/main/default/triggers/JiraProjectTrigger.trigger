/**
 * Trigger for Jira_Project__c to create projects in Jira
 */
trigger JiraProjectTrigger on Jira_Project__c(after insert) {
	// Prevent recursive triggers
	if (JiraTriggerHelper.isRecursive) {
		return;
	}
	
	// Process after insert events
	if (Trigger.operationType == TriggerOperation.AFTER_INSERT) {
		JiraTriggerHelper.isRecursive = true;
		try {
			JiraTriggerHelper.processProjectAfterInsert(Trigger.new);
		} finally {
			JiraTriggerHelper.isRecursive = false;
		}
	}
}
