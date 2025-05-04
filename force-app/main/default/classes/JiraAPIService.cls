/**
 * Service class for making callouts to the Jira API
 */
public with sharing class JiraAPIService {
	// API endpoint constants
	private static final String PROJECT_ENDPOINT = '/project';
	private static final String ISSUE_ENDPOINT = '/issue';
	private static final String LOG_TAG = 'JIRA';
	
	// Strategy interface for API call handling
	private interface JiraCalloutStrategy {
		String getEndpoint();
		Map<String, Object> generatePayload();
		String extractResponse(Map<String, Object> responseMap);
	}
	
	// Project strategy implementation
	private class ProjectCalloutStrategy implements JiraCalloutStrategy {
		private JiraWrapper.ProjectWrapper projectWrapper;
		
		public ProjectCalloutStrategy(JiraWrapper.ProjectWrapper wrapper) {
			this.projectWrapper = wrapper;
		}
		
		public String getEndpoint() {
			return PROJECT_ENDPOINT;
		}
		
		public Map<String, Object> generatePayload() {
			return projectWrapper.generateProjectPayloadMap();
		}
		
		public String extractResponse(Map<String, Object> responseMap) {
			Object idObj = responseMap.get('id');
			if (idObj instanceof String) {
				return (String)idObj;
			} else if (idObj instanceof Integer || idObj instanceof Decimal) {
				return String.valueOf(idObj);
			}
			return null;
		}
	}
	
	// Issue strategy implementation
	private class IssueCalloutStrategy implements JiraCalloutStrategy {
		private JiraWrapper.IssueWrapper issueWrapper;
		
		public IssueCalloutStrategy(JiraWrapper.IssueWrapper wrapper) {
			this.issueWrapper = wrapper;
		}
		
		public String getEndpoint() {
			return ISSUE_ENDPOINT;
		}
		
		public Map<String, Object> generatePayload() {
			return issueWrapper.generateIssuePayloadMap();
		}
		
		public String extractResponse(Map<String, Object> responseMap) {
			return (String)responseMap.get('key');
		}
	}
	
	/**
	 * Makes a callout to the Jira API using the provided strategy
	 * @param strategy The strategy to use for the API call
	 * @return String The response from the API (project ID or issue key)
	 */
	private static String makeCallout(JiraCalloutStrategy strategy) {
		try {
			// Create the HTTP request
			HttpRequest req = new HttpRequest();
			req.setEndpoint('callout:JIRA' + strategy.getEndpoint());
			req.setMethod('POST');
			req.setHeader('Content-Type', 'application/json');
			
			// Set the request body
			req.setBody(JSON.serialize(strategy.generatePayload()));
			
			// Send the request
			Http http = new Http();
			HttpResponse res = http.send(req);
			
			// Process the response
			if (res.getStatusCode() == 201) {
				Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
				return strategy.extractResponse(responseMap);
			} else {
				Logger.error('Error in API call: ' + res.getStatusCode() + ' ' + res.getStatus())
					.addTag(LOG_TAG);
				Logger.saveLog();
				return null;
			}
		} catch (Exception e) {
			Logger.error('Exception in API call: ' + e.getMessage())
				.addTag(LOG_TAG);
			Logger.saveLog();
			return null;
		}
	}
	
	/**
	 * Creates a project in Jira
	 * @param projectWrapper The project wrapper object containing all necessary data
	 * @return String The Jira project ID
	 */
	public static String createProject(JiraWrapper.ProjectWrapper projectWrapper) {
		if (projectWrapper == null) {
			Logger.error('Project wrapper is null')
				.addTag(LOG_TAG);
			Logger.saveLog();
			return null;
		}
		
		return makeCallout(new ProjectCalloutStrategy(projectWrapper));
	}
	
	/**
	 * Creates an issue in Jira
	 * @param issueWrapper The issue wrapper object containing all necessary data
	 * @return String The Jira issue key
	 */
	public static String createIssue(JiraWrapper.IssueWrapper issueWrapper) {
		if (issueWrapper == null) {
			Logger.error('Issue wrapper is null')
				.addTag(LOG_TAG);
			Logger.saveLog();
			return null;
		}
		
		return makeCallout(new IssueCalloutStrategy(issueWrapper));
	}
}
