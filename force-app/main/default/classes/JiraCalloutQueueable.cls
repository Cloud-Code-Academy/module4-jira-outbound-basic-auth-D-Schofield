/**
 * Queueable class to make asynchronous callouts to Jira API
 */
public class JiraCalloutQueueable implements Queueable, Database.AllowsCallouts {
	// Simple constants instead of enum
	public static final String TYPE_PROJECT = 'PROJECT';
	public static final String TYPE_ISSUE = 'ISSUE';

	private String calloutType;
	private Id recordId;
	private JiraWrapper.ProjectWrapper projectWrapper;
	private JiraWrapper.IssueWrapper issueWrapper;

	/**
	 * Constructor for Jira Project callout
	 * @param recordId The Salesforce Jira Project record Id
	 * @param projectName The name of the project
	 * @param projectKey The unique key for the project
	 * @param description Project description
	 */
	public JiraCalloutQueueable(
		Id recordId,
		String projectName,
		String projectKey,
		String description
	) {
		this.calloutType = TYPE_PROJECT;
		this.recordId = recordId;
		this.projectWrapper = new JiraWrapper.ProjectWrapper(projectName, projectKey, description);
	}

	/**
	 * Constructor for Jira Issue callout
	 * @param recordId The Salesforce Jira Issue record Id
	 * @param projectKey The project key where the issue should be created
	 * @param summary The issue summary/title
	 * @param description Issue description
	 * @param issueType The type of issue
	 */
	public JiraCalloutQueueable(
		Id recordId,
		String projectKey,
		String summary,
		String description,
		String issueType
	) {
		this.calloutType = TYPE_ISSUE;
		this.recordId = recordId;
		this.issueWrapper = new JiraWrapper.IssueWrapper(
			projectKey,
			summary,
			description,
			issueType
		);
	}

	/**
	 * Execute the callout based on the callout type
	 * @param context The QueueableContext
	 */
	public void execute(QueueableContext context) {
		try {
			// Check if queueable jobs are enabled
			Queueable_Switch__c switchSetting = Queueable_Switch__c.getInstance();
			if (switchSetting == null || !switchSetting.Run_JIRA_API__c) {
				Logger.info('Queueable job execution stopped by switch setting')
					.addTag('JIRA')
					.setMessage('Queueable_Switch__c.Run_JIRA_API__c is false');
				Logger.saveLog();
				return;
			}
			
			if (calloutType == TYPE_PROJECT) {
				String jiraProjectId = JiraAPIService.createProject(projectWrapper);
				if (String.isNotBlank(jiraProjectId)) {
					updateJiraProject(jiraProjectId);
				}
			} else if (calloutType == TYPE_ISSUE) {
				String jiraIssueKey = JiraAPIService.createIssue(issueWrapper);
				if (String.isNotBlank(jiraIssueKey)) {
					updateJiraIssue(jiraIssueKey);
				}
			}
		} catch (Exception e) {
			Logger.error('Error in JiraCalloutQueueable')
				.addTag('JIRA')
				.setMessage('Exception: ' + e.getMessage() + '\nStack Trace: ' + e.getStackTraceString());
			updateRecordWithError(e.getMessage());
		}
	}

	/**
	 * Update the Jira Project record with the Jira project Id
	 * @param jiraProjectId The ID returned from the Jira API
	 */
	private void updateJiraProject(String jiraProjectId) {
		Jira_Project__c project = new Jira_Project__c(
			Id = recordId,
			Project_ID__c = jiraProjectId
			//Last_Updated__c = Datetime.now()
		);
		update project;
	}

	/**
	 * Update the Jira Issue record with the Jira issue key
	 * @param jiraIssueKey The key returned from the Jira API
	 */
	private void updateJiraIssue(String jiraIssueKey) {
		Jira_Issue__c issue = new Jira_Issue__c(
			Id = recordId,
			Issue_Key__c = jiraIssueKey,
			Last_Updated__c = Datetime.now()
		);
		update issue;
	}

	/**
	 * Update the record with an error message
	 * @param errorMessage The error message to store
	 */
	private void updateRecordWithError(String errorMessage) {
		SObject record;
		if (calloutType == TYPE_PROJECT) {
			record = new Jira_Project__c(
				Id = recordId
				//Error_Message__c = errorMessage,
				//Last_Updated__c = Datetime.now()
			);
		} else if (calloutType == TYPE_ISSUE) {
			record = new Jira_Issue__c(
				Id = recordId
				//Error_Message__c = errorMessage,
				//Last_Updated__c = Datetime.now()
			);
		}
		if (record != null) {
			update record;
		}
	}
}
