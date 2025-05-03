/**
 * Service class for making callouts to the Jira API
 */
public with sharing class JiraAPIService {
	// API endpoint constants
	private static final String PROJECT_ENDPOINT = '/project';
	private static final String ISSUE_ENDPOINT = '/issue';
	
	/**
	 * Creates a project in Jira
	 * @param projectWrapper The project wrapper object containing all necessary data
	 * @return String The Jira project ID
	 */
	public static String createProject(JiraWrapper.ProjectWrapper projectWrapper) {
		// Validate input
		if (projectWrapper == null) {
			Logger.error('Project wrapper is null')
				.addTag('JIRA');
			Logger.saveLog();
			return null;
		}
		
		try {
			// Create the HTTP request
			HttpRequest req = new HttpRequest();
			req.setEndpoint('callout:JIRA' + PROJECT_ENDPOINT);
			req.setMethod('POST');
			req.setHeader('Content-Type', 'application/json');
			
			// Generate the project payload
			Map<String, Object> requestBody = projectWrapper.generateProjectPayloadMap();
			
			// Set the request body
			req.setBody(JSON.serialize(requestBody));
			
			// Send the request
			Http http = new Http();
			HttpResponse res = http.send(req);
			
			// Process the response
			if (res.getStatusCode() == 201) {
				// Parse the response
				Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
				
				// Extract and return the project ID
				Object idObj = responseMap.get('id');
				// Handle both string and number types for the id field
				if (idObj instanceof String) {
					return (String)idObj;
				} else if (idObj instanceof Integer || idObj instanceof Decimal) {
					return String.valueOf(idObj);
				} else {
					Logger.error('Unexpected id type')
						.addTag('JIRA');
					Logger.saveLog();
					return null;
				}
			} else {
				// Log the error
				Logger.error('Error creating project: ' + res.getStatusCode() + ' ' + res.getStatus())
					.addTag('JIRA');
				Logger.saveLog();
				return null;
			}
		} catch (Exception e) {
			// Log the exception
			Logger.error('Exception in project creation: ' + e.getMessage())
				.addTag('JIRA');
			Logger.saveLog();
			return null;
		}
	}

	/**
	 * Creates an issue in Jira
	 * @param issueWrapper The issue wrapper object containing all necessary data
	 * @return String The Jira issue key
	 */
	public static String createIssue(JiraWrapper.IssueWrapper issueWrapper) {
		// Validate input
		if (issueWrapper == null) {
			Logger.error('Issue wrapper is null')
				.addTag('JIRA');
			Logger.saveLog();
			return null;
		}
		
		try {
			// Create the HTTP request
			HttpRequest req = new HttpRequest();
			req.setEndpoint('callout:JIRA' + ISSUE_ENDPOINT);
			req.setMethod('POST');
			req.setHeader('Content-Type', 'application/json');
			
			// Generate the issue payload
			Map<String, Object> requestBody = issueWrapper.generateIssuePayloadMap();
			
			// Set the request body
			req.setBody(JSON.serialize(requestBody));
			
			// Send the request
			Http http = new Http();
			HttpResponse res = http.send(req);
			
			// Process the response
			if (res.getStatusCode() == 201) {
				// Parse the response
				Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
				
				// Extract and return the issue key
				return (String)responseMap.get('key');
			} else {
				// Log the error
				Logger.error('Error creating issue: ' + res.getStatusCode() + ' ' + res.getStatus())
					.addTag('JIRA');
				Logger.saveLog();
				return null;
			}
		} catch (Exception e) {
			// Log the exception
			Logger.error('Exception in issue creation: ' + e.getMessage())
				.addTag('JIRA');
			Logger.saveLog();
			return null;
		}
	}
}
