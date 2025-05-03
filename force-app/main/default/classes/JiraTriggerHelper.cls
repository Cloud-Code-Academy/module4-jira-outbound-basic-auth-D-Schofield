/**
 * Helper class for Jira triggers
 */
public with sharing class JiraTriggerHelper {
	/**
	 * Process Jira_Project__c records after insert
	 * @param newProjects List of newly inserted Jira_Project__c records
	 */
	public static void processProjectAfterInsert(List<Jira_Project__c> newProjects) {
		List<Jira_Project__c> projectsToProcess = new List<Jira_Project__c>();

		// Filter out projects that already have a Jira project ID
		for (Jira_Project__c project : newProjects) {
			if (String.isBlank(project.Project_ID__c)) {
				projectsToProcess.add(project);
			}
		}

		// Simple bulkification by looping through each project
		for (Jira_Project__c project : projectsToProcess) {
			// Enqueue the callout
			JiraCalloutQueueable callout = new JiraCalloutQueueable(
				project.Id,
				project.Project_Name__c,
				project.Project_Key__c,
				project.Description__c
			);

			if (!Test.isRunningTest()) {
				System.enqueueJob(callout);
			}
		}
	}

	/**
	 * Process Jira_Issue__c records after insert
	 * @param newIssues List of newly inserted Jira_Issue__c records
	 */
	public static void processIssueAfterInsert(List<Jira_Issue__c> newIssues) {
		List<Jira_Issue__c> issuesToProcess = new List<Jira_Issue__c>();

		// Filter out issues that already have a Jira issue key and ensure Project_Key__c is not blank
		for (Jira_Issue__c issue : newIssues) {
			if (String.isBlank(issue.Issue_Key__c) && String.isNotBlank(issue.Project_Key__c)) {
				issuesToProcess.add(issue);
			}
		}

		// Simple bulkification by looping through each issue
		for (Jira_Issue__c issue : issuesToProcess) {
			// Enqueue the callout
			JiraCalloutQueueable callout = new JiraCalloutQueueable(
				issue.Id,
				issue.Project_Key__c,
				issue.Summary__c,
				issue.Description__c,
				issue.Issue_Type__c
			);

			if (!Test.isRunningTest()) {
				System.enqueueJob(callout);
			}
		}
	}

	/**
	 * Process Jira_Issue__c records after update
	 * @param newIssues List of updated Jira_Issue__c records
	 * @param oldIssues Map of old Jira_Issue__c records
	 */
	public static void processIssueAfterUpdate(List<Jira_Issue__c> newIssues, Map<Id, Jira_Issue__c> oldIssues) {
		List<Jira_Issue__c> issuesToProcess = new List<Jira_Issue__c>();

		// Filter issues that have relevant field changes and have a Jira issue key
		for (Jira_Issue__c newIssue : newIssues) {
			Jira_Issue__c oldIssue = oldIssues.get(newIssue.Id);
			
			// Only process if the issue has a Jira key and relevant fields have changed
			if (String.isNotBlank(newIssue.Issue_Key__c) &&
				(newIssue.Summary__c != oldIssue.Summary__c ||
				newIssue.Description__c != oldIssue.Description__c ||
				newIssue.Issue_Type__c != oldIssue.Issue_Type__c)) {
				issuesToProcess.add(newIssue);
			}
		}

		// Process each issue that needs updating
		for (Jira_Issue__c issue : issuesToProcess) {
			// Enqueue the callout
			JiraCalloutQueueable callout = new JiraCalloutQueueable(
				issue.Id,
				issue.Project_Key__c,
				issue.Summary__c,
				issue.Description__c,
				issue.Issue_Type__c
			);

			if (!Test.isRunningTest()) {
				System.enqueueJob(callout);
			}
		}
	}
}
