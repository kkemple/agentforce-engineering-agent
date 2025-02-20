public class SearchGitHubPRsAction {

    /**
     * Input class for the Agentforce action
     * Provides structured inputs for common PR search criteria
     */
    public class SearchPRsInput {
        @InvocableVariable(description='Text to search for in PR title and body')
        public String search_text;

        @InvocableVariable(description='Repository to search in')
        public String repository;

        @InvocableVariable(description='Organization to search within')
        public String organization;

        @InvocableVariable(description='State of PRs to find (open, closed, or all)')
        public String state;

        @InvocableVariable(description='Author username to filter by')
        public String author;

        @InvocableVariable(description='Assignee username to filter by')
        public String assignee;

        @InvocableVariable(description='Labels to filter by (comma-separated)')
        public String labels;

        @InvocableVariable(description='How to sort results (comments, reactions, created, updated)')
        public String sort_by;

        @InvocableVariable(description='Direction of sort (asc or desc)')
        public String direction;

        @InvocableVariable(description='Number of results per page (max 100)')
        public Integer per_page;
    }

    /**
     * Class representing a GitHub pull request search result
     */
    public class PullRequestSearchResult {
        @InvocableVariable(description='Pull request number')
        public Integer pr_number;

        @InvocableVariable(description='Pull request title')
        public String title;

        @InvocableVariable(description='Pull request state (open, closed)')
        public String state;

        @InvocableVariable(description='Repository full name')
        public String repository_full_name;

        @InvocableVariable(description='Pull request author username')
        public String author;

        @InvocableVariable(description='Labels on the pull request')
        public List<String> labels;

        @InvocableVariable(description='HTML URL of the pull request')
        public String html_url;

        @InvocableVariable(description='Pull request body/description')
        public String body;

        @InvocableVariable(description='Created date')
        public DateTime created_at;

        @InvocableVariable(description='Last updated date')
        public DateTime updated_at;

        @InvocableVariable(description='Closed date')
        public DateTime closed_at;

        @InvocableVariable(description='Number of comments')
        public Integer comments;

        @InvocableVariable(description='Score of the search result')
        public Double score;
    }

    /**
     * Output class containing search results and metadata
     */
    public class SearchPRsOutput {
        @InvocableVariable(description='Total number of matching results')
        public Integer total_count;

        @InvocableVariable(description='Whether the results are incomplete')
        public Boolean incomplete_results;

        @InvocableVariable(description='List of matching pull requests')
        public List<PullRequestSearchResult> pull_requests;

        @InvocableVariable(description='Query string built by inputs')
        public String queryString;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;

        public SearchPRsOutput() {
            pull_requests = new List<PullRequestSearchResult>();
        }
    }

    /**
     * Main invocable method for the Agentforce action
     */
    @InvocableMethod(label='Search GitHub Pull Requests'
                     description='Searches for pull requests across GitHub using structured search criteria')
    public static List<SearchPRsOutput> searchPullRequests(List<SearchPRsInput> inputs) {
        List<SearchPRsOutput> outputs = new List<SearchPRsOutput>();

        for(SearchPRsInput input : inputs) {
            SearchPRsOutput output = new SearchPRsOutput();

            try {
                // Build the search query from structured inputs
                List<String> queryParts = new List<String>();

                // add the search text
                queryParts.add('q=' + input.search_text);

                // Always include is:pr to search only pull requests
                queryParts.add('is:pull-request');

                // Add repository filter if specified
                if (String.isNotBlank(input.repository)) {
                    queryParts.add('repo:' + input.repository);
                }

                // Add organization filter if specified
                if (String.isNotBlank(input.organization)) {
                    queryParts.add('org:' + input.organization);
                }

                // Add state filter if specified
                if (String.isNotBlank(input.state)) {
                    queryParts.add('state:' + input.state);
                }

                // Add author filter if specified
                if (String.isNotBlank(input.author)) {
                    queryParts.add('author:' + input.author);
                }

                // Add assignee filter if specified
                if (String.isNotBlank(input.assignee)) {
                    queryParts.add('assignee:' + input.assignee);
                }

                // Add label filters if specified
                if (String.isNotBlank(input.labels)) {
                    List<String> labelsList = input.labels.split(',');
                    for (String label : labelsList) {
                        queryParts.add('label:' + label.trim());
                    }
                }

                String query = String.join(queryParts, '+');

                Http http = new Http();
                HttpRequest request = new HttpRequest();

                // Build the endpoint URL with search parameters
                String endpoint = 'callout:GitHub_API/search/issues?' + query;

                // Add optional sort and pagination parameters
                List<String> params = new List<String>();

                if (String.isNotBlank(input.sort_by)) {
                    params.add('sort=' + input.sort_by);
                }

                if (String.isNotBlank(input.direction)) {
                    params.add('direction=' + input.direction);
                }

                if (input.per_page != null) {
                    params.add('per_page=' + Math.min(input.per_page, 100));
                }

                if (!params.isEmpty()) {
                    endpoint += '&' + String.join(params, '&');
                }

                request.setEndpoint(endpoint);
                request.setMethod('GET');

                // Add header for text match metadata
                request.setHeader('Accept', 'application/vnd.github.text-match+json');

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 200) {
                    Map<String, Object> searchResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

                    output.total_count = Integer.valueOf(searchResponse.get('total_count'));
                    output.incomplete_results = (Boolean)searchResponse.get('incomplete_results');
                    output.queryString = query;

                    List<Object> items = (List<Object>)searchResponse.get('items');

                    for (Object item : items) {
                        Map<String, Object> prMap = (Map<String, Object>)item;
                        PullRequestSearchResult pr = new PullRequestSearchResult();

                        pr.pr_number = Integer.valueOf(prMap.get('number'));
                        pr.title = (String)prMap.get('title');
                        pr.state = (String)prMap.get('state');
                        pr.html_url = (String)prMap.get('html_url');
                        pr.body = (String)prMap.get('body');

                        // Get repository information from repository_url
                        String repoUrl = (String)prMap.get('repository_url');
                        if (String.isNotBlank(repoUrl)) {
                            List<String> urlParts = repoUrl.split('/');
                            pr.repository_full_name = urlParts[urlParts.size()-2] + '/' + urlParts[urlParts.size()-1];
                        }

                        // Get author info
                        Map<String, Object> user = (Map<String, Object>)prMap.get('user');
                        if (user != null) {
                            pr.author = (String)user.get('login');
                        }

                        // Get labels
                        pr.labels = new List<String>();
                        List<Object> labelsList = (List<Object>)prMap.get('labels');
                        for (Object labelObj : labelsList) {
                            Map<String, Object> label = (Map<String, Object>)labelObj;
                            pr.labels.add((String)label.get('name'));
                        }

                        pr.comments = Integer.valueOf(prMap.get('comments'));
                        pr.score = Double.valueOf(prMap.get('score'));

                        // Handle date conversions
                        String createdStr = (String)prMap.get('created_at');
                        String updatedStr = (String)prMap.get('updated_at');
                        String closedStr = (String)prMap.get('closed_at');

                        if (String.isNotBlank(createdStr)) {
                            pr.created_at = DateTime.valueOfGmt(createdStr.replace('T', ' ').replace('Z', ' '));
                        }

                        if (String.isNotBlank(updatedStr)) {
                            pr.updated_at = DateTime.valueOfGmt(updatedStr.replace('T', ' ').replace('Z', ' '));
                        }

                        if (String.isNotBlank(closedStr)) {
                            pr.closed_at = DateTime.valueOfGmt(closedStr.replace('T', ' ').replace('Z', ' '));
                        }

                        output.pull_requests.add(pr);
                    }
                } else {
                    output.error_message = 'Failed with status code: ' + response.getStatusCode();
                    output.queryString = query;
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
