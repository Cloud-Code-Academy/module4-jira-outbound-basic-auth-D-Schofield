/**
 * Wrapper classes for Jira entities (Project and Issue)
 */
public class JiraWrapper {
	private static final String LEAD_ACCOUNT_ID = '70121:6121a1df-45be-4acc-9fbd-fbaaf888590e';
	private static final String PROJECT_TEMPLATE_KEY = 'com.pyxis.greenhopper.jira:basic-software-development-template';

	/**
	 * Wrapper for Jira Project
	 */
	public class ProjectWrapper {
		public String name;
		public String key;
		public String description;
		public String leadAccountId;
		public String projectTemplateKey;

		/**
		 * Constructor for ProjectWrapper
		 */
		public ProjectWrapper(String name, String key, String description) {
			this.name = name;
			this.key = key;
			this.description = description;
			this.leadAccountId = LEAD_ACCOUNT_ID;
			this.projectTemplateKey = PROJECT_TEMPLATE_KEY;
		}

		/**
		 * Convert ProjectWrapper to a Map for serialization
		 *
		 * Creates a Map that represents the JSON payload needed for the Jira API.
		 * The Map contains:
		 * - key: The project key
		 * - name: The project name
		 * - projectTypeKey: Set to 'software'
		 * - projectTemplateKey: The template key for the project
		 * - description: The project description
		 * - leadAccountId: The account ID of the project lead
		 * 
		 * @return Map<String, Object> representing the JSON payload
		 */
		public Map<String, Object> generateProjectPayloadMap() {
			return new Map<String, Object>{
				'key' => this.key,
				'name' => this.name,
				'projectTypeKey' => 'software',
				'projectTemplateKey' => this.projectTemplateKey,
				'description' => this.description,
				'leadAccountId' => this.leadAccountId
			};
		}
	}

	/**
	 * Wrapper for Jira Issue
	 */
	public class IssueWrapper {
		public String name;
		public String key;
		public String description;
		public String projectKey;
		public String summary;
		public String issueType;

		/**
		 * Constructor for IssueWrapper
		 */
		public IssueWrapper(
			String projectKey,
			String summary,
			String description,
			String issueType
		) {
			this.projectKey = projectKey;
			this.summary = summary;
			this.description = description;
			this.issueType = (String.isNotBlank(issueType)) ? issueType : 'Task';
		}

		/**
		 * Convert IssueWrapper to a Map for serialization
		 *
		 * TODO: Implement this method to create a Map that represents
		 * the JSON payload needed for the Jira API. 
		 * 
		 * The Map should contain:
		 * - fields object with project information (key)
		 * - issuetype object with the issue type name
		 * - summary field
		 * - description field (formatted using formatDescription method)
		 * 
		 * - Example:
		 */
		public Map<String, Object> generateIssuePayloadMap() {
			Map<String, Object> payload = new Map<String, Object>();
			
			// Build the fields map using arrow notation
			Map<String, Object> fieldsObj = new Map<String, Object>{
				'project' => new Map<String, Object>{'key' => this.projectKey},
				// Note: The issue type might need to be an ID instead of a name depending on JIRA API version
				'issuetype' => new Map<String, Object>{'name' => this.issueType},
				'summary' => this.summary,
				'description' => formatDescription(this.description)
			};
			payload.put('fields', fieldsObj);
			return payload;
		}

		/**
		 * Format the description text according to JIRA Cloud API requirements
		 * @param descText The description text to format
		 * @return Map<String, Object> representing the formatted description
		 */
		private Map<String, Object> formatDescription(String descText) {
			// Return null if description is blank
			if (String.isBlank(descText)) {
				return null;
			}
			
			// Create the description map with type and content
			return new Map<String, Object>{
				'type' => 'doc',
				'version' => 1,
				'content' => new List<Object>{
					new Map<String, Object>{
						'type' => 'paragraph',
						'content' => new List<Object>{
							new Map<String, Object>{
								'type' => 'text',
								'text' => descText
							}
						}
					}
				}
			};
		}
	}
}
