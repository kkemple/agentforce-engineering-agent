public class GetGitHubRepositoryPRsAction {

    /**
     * Input class for the Agentforce action
     */
    public class GetPullRequestsInput {
        @InvocableVariable(required=true description='The owner of the repository')
        public String owner;

        @InvocableVariable(required=true description='The name of the repository')
        public String repo;

        @InvocableVariable(description='State of pull requests to return (open, closed, or all)')
        public String state;

        @InvocableVariable(description='Sort field (created, updated, popularity, long-running)')
        public String sort_by;

        @InvocableVariable(description='Direction of sort (asc or desc)')
        public String direction;
    }

    /**
     * Class representing a GitHub pull request
     */
    public class PullRequestInfo {
        @InvocableVariable(description='Pull request number')
        public Integer pr_number;

        @InvocableVariable(description='Pull request title')
        public String title;

        @InvocableVariable(description='State of the pull request')
        public String state;

        @InvocableVariable(description='Pull request body/description')
        public String body;

        @InvocableVariable(description='HTML URL of the pull request')
        public String html_url;

        @InvocableVariable(description='Source branch name')
        public String head_ref;

        @InvocableVariable(description='Target branch name')
        public String base_ref;

        @InvocableVariable(description='User who created the pull request')
        public String user_login;

        @InvocableVariable(description='Whether the PR is in draft state')
        public Boolean draft;

        @InvocableVariable(description='Whether the PR can be merged')
        public Boolean mergeable;

        @InvocableVariable(description='Number of commits in the PR')
        public Integer commits;

        @InvocableVariable(description='Number of file changes')
        public Integer changed_files;

        @InvocableVariable(description='Created date')
        public DateTime created_at;

        @InvocableVariable(description='Last updated date')
        public DateTime updated_at;

        @InvocableVariable(description='Closed date')
        public DateTime closed_at;

        @InvocableVariable(description='Merged date')
        public DateTime merged_at;
    }

    /**
     * Output class containing pull requests or error information
     */
    public class GetPullRequestsOutput {
        @InvocableVariable(description='List of pull requests matching the criteria')
        public List<PullRequestInfo> pull_requests;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;

        public GetPullRequestsOutput() {
            pull_requests = new List<PullRequestInfo>();
        }
    }

    /**
     * Main invocable method for the Agentforce action
     */
    @InvocableMethod(label='Get GitHub Repository Pull Requests'
                     description='Retrieves pull requests for a GitHub repository with optional filtering and sorting')
    public static List<GetPullRequestsOutput> getPullRequests(List<GetPullRequestsInput> inputs) {
        List<GetPullRequestsOutput> outputs = new List<GetPullRequestsOutput>();

        for(GetPullRequestsInput input : inputs) {
            GetPullRequestsOutput output = new GetPullRequestsOutput();

            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();

                // Build the query string with parameters
                String endpoint = 'callout:GitHub_API/repos/' + input.owner + '/' + input.repo + '/pulls?';
                List<String> params = new List<String>();

                if (String.isNotBlank(input.state)) {
                    params.add('state=' + EncodingUtil.urlEncode(input.state, 'UTF-8'));
                }

                if (String.isNotBlank(input.sort_by)) {
                    params.add('sort=' + EncodingUtil.urlEncode(input.sort_by, 'UTF-8'));
                }

                if (String.isNotBlank(input.direction)) {
                    params.add('direction=' + EncodingUtil.urlEncode(input.direction, 'UTF-8'));
                }

                endpoint += String.join(params, '&');
                request.setEndpoint(endpoint);
                request.setMethod('GET');

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 200) {
                    List<Object> prsData = (List<Object>)JSON.deserializeUntyped(response.getBody());

                    for (Object prObj : prsData) {
                        Map<String, Object> prMap = (Map<String, Object>)prObj;
                        PullRequestInfo pr = new PullRequestInfo();

                        pr.pr_number = Integer.valueOf(prMap.get('number'));
                        pr.title = (String)prMap.get('title');
                        pr.state = (String)prMap.get('state');
                        pr.body = (String)prMap.get('body');
                        pr.html_url = (String)prMap.get('html_url');

                        // Get the head and base branch names
                        Map<String, Object> head = (Map<String, Object>)prMap.get('head');
                        Map<String, Object> base = (Map<String, Object>)prMap.get('base');
                        pr.head_ref = (String)head.get('ref');
                        pr.base_ref = (String)base.get('ref');

                        // Get the user login
                        Map<String, Object> user = (Map<String, Object>)prMap.get('user');
                        pr.user_login = (String)user.get('login');

                        pr.draft = (Boolean)prMap.get('draft');
                        pr.mergeable = (Boolean)prMap.get('mergeable');
                        pr.commits = Integer.valueOf(prMap.get('commits'));
                        pr.changed_files = Integer.valueOf(prMap.get('changed_files'));

                        // Handle date conversions
                        String createdStr = (String)prMap.get('created_at');
                        String updatedStr = (String)prMap.get('updated_at');
                        String closedStr = (String)prMap.get('closed_at');
                        String mergedStr = (String)prMap.get('merged_at');

                        if (String.isNotBlank(createdStr)) {
                            pr.created_at = DateTime.valueOfGmt(createdStr.replace('T', ' ').replace('Z', ' '));
                        }

                        if (String.isNotBlank(updatedStr)) {
                            pr.updated_at = DateTime.valueOfGmt(updatedStr.replace('T', ' ').replace('Z', ' '));
                        }

                        if (String.isNotBlank(closedStr)) {
                            pr.closed_at = DateTime.valueOfGmt(closedStr.replace('T', ' ').replace('Z', ' '));
                        }

                        if (String.isNotBlank(mergedStr)) {
                            pr.merged_at = DateTime.valueOfGmt(mergedStr.replace('T', ' ').replace('Z', ' '));
                        }

                        output.pull_requests.add(pr);
                    }
                } else {
                    output.error_message = 'Failed with status code: ' + response.getStatusCode();
                    System.debug('Error response: ' + response.getBody());
                }

            } catch(Exception e) {
                output.error_message = 'Error: ' + e.getMessage();
                System.debug('Error details: ' + e.getStackTraceString());
            }

            outputs.add(output);
        }

        return outputs;
    }
}
