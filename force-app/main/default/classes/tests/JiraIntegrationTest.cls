/**
 * Test class for Jira integration
 * Tests JiraAPIService and JiraCalloutQueueable classes
 */
@isTest
private class JiraIntegrationTest {
	// Test data constants
	private static final String TEST_PROJECT_NAME = 'Test Project';
	private static final String TEST_PROJECT_KEY = 'TP1';
	private static final String TEST_DESCRIPTION = 'Test Description';
	private static final String TEST_ISSUE_SUMMARY = 'Test Issue Summary';
	private static final String TEST_ISSUE_TYPE = 'Task';

	/**
	 * Setup test data
	 */
	@TestSetup
	static void setupTestData() {
		// Create and set the Queueable_Switch__c custom setting
		Queueable_Switch__c switchSetting = new Queueable_Switch__c(
			SetupOwnerId = UserInfo.getOrganizationId(),
			Run_JIRA_API__c = true
		);
		insert switchSetting;

		// Create a test Jira Project record
		Jira_Project__c project = new Jira_Project__c(
			Project_Name__c = TEST_PROJECT_NAME,
			Project_Key__c = TEST_PROJECT_KEY,
			Description__c = TEST_DESCRIPTION
		);
		insert project;

		// Create a test Jira Issue record
		Jira_Issue__c issue = new Jira_Issue__c(
			Project_Key__c = TEST_PROJECT_KEY,
			Summary__c = TEST_ISSUE_SUMMARY,
			Description__c = TEST_DESCRIPTION,
			Issue_Type__c = TEST_ISSUE_TYPE
		);
		insert issue;
	}

	/**
	 * Test successful project creation via JiraAPIService
	 */
	@isTest
	static void testCreateProjectSuccess() {
		// Setup the mock
		Test.setMock(HttpCalloutMock.class, new JiraMockHttpResponseGenerator(true, true));

		// Start the test
		Test.startTest();

		// Create a project wrapper
		JiraWrapper.ProjectWrapper projectWrapper = new JiraWrapper.ProjectWrapper(
			TEST_PROJECT_NAME,
			TEST_PROJECT_KEY,
			TEST_DESCRIPTION
		);

		// Call the method to test
		String projectId = JiraAPIService.createProject(projectWrapper);

		Test.stopTest();

		// Verify results
		Assert.areEqual(
			JiraMockHttpResponseGenerator.getMockProjectId(),
			projectId,
			'Project ID should match the mock response'
		);
	}

	/**
	 * Test failed project creation via JiraAPIService
	 */
	@isTest
	static void testCreateProjectFailure() {
		// Setup the mock to return an error response
		Test.setMock(HttpCalloutMock.class, new JiraMockHttpResponseGenerator(false, true));

		// Start the test
		Test.startTest();

		// Create a project wrapper
		JiraWrapper.ProjectWrapper projectWrapper = new JiraWrapper.ProjectWrapper(
			TEST_PROJECT_NAME,
			TEST_PROJECT_KEY,
			TEST_DESCRIPTION
		);

		// Call the method to test
		String projectId = JiraAPIService.createProject(projectWrapper);

		Test.stopTest();

		// Verify results
		Assert.isNull(projectId, 'Project ID should be null due to API failure');
	}

	/**
	 * Test successful issue creation via JiraAPIService
	 */
	@isTest
	static void testCreateIssueSuccess() {
		// Setup the mock
		Test.setMock(HttpCalloutMock.class, new JiraMockHttpResponseGenerator(true, false));

		// Start the test
		Test.startTest();

		// Create an issue wrapper
		JiraWrapper.IssueWrapper issueWrapper = new JiraWrapper.IssueWrapper(
			TEST_PROJECT_KEY,
			TEST_ISSUE_SUMMARY,
			TEST_DESCRIPTION,
			TEST_ISSUE_TYPE
		);

		// Call the method to test
		String issueKey = JiraAPIService.createIssue(issueWrapper);

		Test.stopTest();

		// Verify results
		Assert.areEqual(
			JiraMockHttpResponseGenerator.getMockIssueKey(),
			issueKey,
			'Issue key should match the mock response'
		);
	}

	/**
	 * Test failed issue creation via JiraAPIService
	 */
	@isTest
	static void testCreateIssueFailure() {
		// Setup the mock to return an error response
		Test.setMock(HttpCalloutMock.class, new JiraMockHttpResponseGenerator(false, false));

		// Start the test
		Test.startTest();

		// Create an issue wrapper
		JiraWrapper.IssueWrapper issueWrapper = new JiraWrapper.IssueWrapper(
			TEST_PROJECT_KEY,
			TEST_ISSUE_SUMMARY,
			TEST_DESCRIPTION,
			TEST_ISSUE_TYPE
		);

		// Call the method to test
		String issueKey = JiraAPIService.createIssue(issueWrapper);

		Test.stopTest();

		// Verify results
		Assert.isNull(issueKey, 'Issue key should be null due to API failure');
	}

	/**
	 * Test JiraCalloutQueueable for project creation
	 */
	@isTest
	static void testProjectCalloutQueueable() {
		// Setup the mock
		Test.setMock(HttpCalloutMock.class, new JiraMockHttpResponseGenerator(true, true));

		// Get the test project ID
		Jira_Project__c project = [SELECT Id FROM Jira_Project__c LIMIT 1];

		// Start the test
		Test.startTest();

		// Create and enqueue the queueable job
		JiraCalloutQueueable queueable = new JiraCalloutQueueable(
			project.Id,
			TEST_PROJECT_NAME,
			TEST_PROJECT_KEY,
			TEST_DESCRIPTION
		);

		System.enqueueJob(queueable);

		Test.stopTest();

		// Verify the project was updated
		Jira_Project__c updatedProject = [
			SELECT Id, Project_ID__c
			FROM Jira_Project__c
			WHERE Id = :project.Id
		];
		Assert.areEqual(
			JiraMockHttpResponseGenerator.getMockProjectId(),
			updatedProject.Project_ID__c,
			'The project should be updated with the Jira project ID'
		);
	}

	/**
	 * Test JiraCalloutQueueable for issue creation
	 */
	@isTest
	static void testIssueCalloutQueueable() {
		// Setup the mock
		Test.setMock(HttpCalloutMock.class, new JiraMockHttpResponseGenerator(true, false));

		// Get the test issue ID
		Jira_Issue__c issue = [SELECT Id FROM Jira_Issue__c LIMIT 1];

		// Start the test
		Test.startTest();

		// Create and enqueue the queueable job
		JiraCalloutQueueable queueable = new JiraCalloutQueueable(
			issue.Id,
			TEST_PROJECT_KEY,
			TEST_ISSUE_SUMMARY,
			TEST_DESCRIPTION,
			TEST_ISSUE_TYPE
		);

		// Execute the queueable
		System.enqueueJob(queueable);

		Test.stopTest();

		// Verify the issue was updated
		Jira_Issue__c updatedIssue = [
			SELECT Id, Issue_Key__c
			FROM Jira_Issue__c
			WHERE Id = :issue.Id
		];
		Assert.areEqual(
			JiraMockHttpResponseGenerator.getMockIssueKey(),
			updatedIssue.Issue_Key__c,
			'The issue should be updated with the Jira issue key'
		);
	}
}
