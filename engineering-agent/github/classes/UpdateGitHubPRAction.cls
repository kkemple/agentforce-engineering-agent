/**
 * Class for updating GitHub Pull Requests
 */
public class UpdateGitHubPRAction {

    /**
     * Input class for the Agentforce PR update action
     * Provides structured inputs for PR updates
     */
    public class UpdatePRInput {
        @InvocableVariable(required=true description='Repository containing the PR (format: owner/repo)')
        public String repository;

        @InvocableVariable(required=true description='The number that identifies the PR')
        public Integer pull_number;

        @InvocableVariable(description='New title for the PR')
        public String title;

        @InvocableVariable(description='New body/description for the PR')
        public String body;

        @InvocableVariable(description='State of the PR (open or closed)')
        public String state;

        @InvocableVariable(description='Branch to pull changes into')
        public String base;
    }

    /**
     * Class representing a PR update result
     */
    public class PRUpdateResult {
        @InvocableVariable(description='Whether the update was successful')
        public Boolean success;

        @InvocableVariable(description='Pull request number')
        public Integer pull_number;

        @InvocableVariable(description='Current PR title')
        public String title;

        @InvocableVariable(description='Current PR state')
        public String state;

        @InvocableVariable(description='URL of the PR')
        public String url;

        @InvocableVariable(description='Error message if update failed')
        public String error_message;
    }

    /**
     * Main invocable method for updating a GitHub pull request
     */
    @InvocableMethod(label='Update GitHub Pull Request' description='Updates a GitHub pull request')
    public static List<PRUpdateResult> updatePullRequest(List<UpdatePRInput> inputs) {
        List<PRUpdateResult> results = new List<PRUpdateResult>();

        for(UpdatePRInput input : inputs) {
            PRUpdateResult result = new PRUpdateResult();
            result.pull_number = input.pull_number;

            try {
                // Validate repository format
                if (!input.repository.contains('/')) {
                    throw new IllegalArgumentException('Repository must be in format owner/repo');
                }

                Http http = new Http();
                HttpRequest request = new HttpRequest();

                // Build the endpoint URL for updating the PR
                String endpoint = 'callout:GitHub_API/repos/' + input.repository +
                    '/pulls/' + input.pull_number;

                request.setEndpoint(endpoint);
                request.setMethod('PATCH');
                request.setHeader('Accept', 'application/vnd.github+json');

                // Build update payload
                Map<String, Object> updateBody = new Map<String, Object>();

                if (String.isNotBlank(input.title)) {
                    updateBody.put('title', input.title);
                }
                if (String.isNotBlank(input.body)) {
                    updateBody.put('body', input.body);
                }
                if (String.isNotBlank(input.state)) {
                    updateBody.put('state', input.state.toLowerCase());
                }
                if (String.isNotBlank(input.base)) {
                    updateBody.put('base', input.base);
                }

                request.setBody(JSON.serialize(updateBody));

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 200) {
                    Map<String, Object> prData = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

                    result.success = true;
                    result.title = (String)prData.get('title');
                    result.state = (String)prData.get('state');
                    result.url = (String)prData.get('html_url');
                } else {
                    result.success = false;
                    result.error_message = 'Update failed with status code: ' +
                        response.getStatusCode() + '. Response: ' + response.getBody();
                }

            } catch(Exception e) {
                result.success = false;
                result.error_message = 'Error: ' + e.getMessage();
                System.debug('Error details: ' + e.getStackTraceString());
            }

            results.add(result);
        }

        return results;
    }
}
