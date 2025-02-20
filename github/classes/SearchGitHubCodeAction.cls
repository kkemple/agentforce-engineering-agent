public class SearchGitHubCodeAction {

    /**
     * Input class for the Agentforce action
     * Breaks down search parameters into structured fields rather than requiring query syntax
     */
    public class SearchCodeInput {
        @InvocableVariable(required=true description='Text to search for in the code')
        public String search_text;

        @InvocableVariable(description='Repository to search in')
        public String repository;

        @InvocableVariable(description='Organization to search within')
        public String organization;

        @InvocableVariable(description='Programming language to filter by')
        public String language;

        @InvocableVariable(description='Where to search (file, path, or blank for both)')
        public String search_in;

        @InvocableVariable(description='Number of results per page (max 100)')
        public Integer per_page;
    }

    /**
     * Class representing a GitHub code search result
     * Includes information about the matching file and its location
     */
    public class CodeSearchResult {
        @InvocableVariable(description='Name of the file')
        public String name;

        @InvocableVariable(description='Path to the file in the repository')
        public String path;

        @InvocableVariable(description='SHA hash of the file')
        public String sha;

        @InvocableVariable(description='URL to view the file')
        public String html_url;

        @InvocableVariable(description='URL to get the raw file content')
        public String raw_url;

        @InvocableVariable(description='URL to get the Git blob')
        public String git_url;

        @InvocableVariable(description='Repository full name')
        public String repository_full_name;

        @InvocableVariable(description='Score of the search result')
        public Double score;

        @InvocableVariable(description='Text matches showing where the search terms were found')
        public List<TextMatch> text_matches;
    }

    /**
     * Class representing a text match in the search results
     * Shows the exact location and context of search terms
     */
    public class TextMatch {
        @InvocableVariable(description='Object type that matched')
        public String object_type;

        @InvocableVariable(description='Property that contained the match')
        public String property;

        @InvocableVariable(description='Fragment of text containing the match')
        public String fragment;

        @InvocableVariable(description='List of matching terms in the fragment')
        public List<String> matches;
    }

    /**
     * Output class containing search results and metadata
     */
    public class SearchCodeOutput {
        @InvocableVariable(description='Total number of matching results')
        public Integer total_count;

        @InvocableVariable(description='Whether the results are incomplete')
        public Boolean incomplete_results;

        @InvocableVariable(description='List of matching code results')
        public List<CodeSearchResult> code_results;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;

        public SearchCodeOutput() {
            code_results = new List<CodeSearchResult>();
        }
    }

    /**
     * Main invocable method for the Agentforce action
     * Searches for code using the GitHub Search API
     * Note: Code search has special rate limits (10 requests per minute)
     */
    @InvocableMethod(label='Search GitHub Code'
                     description='Searches for code within a GitHub repository with support for language and path filtering')
    public static List<SearchCodeOutput> searchCode(List<SearchCodeInput> inputs) {
        List<SearchCodeOutput> outputs = new List<SearchCodeOutput>();

        for(SearchCodeInput input : inputs) {
            SearchCodeOutput output = new SearchCodeOutput();

            try {
                // Build the search query from structured inputs
                List<String> queryParts = new List<String>();

                // Add the main search text
                queryParts.add(input.search_text);

                // Add repository filter if specified
                if (String.isNotBlank(input.repository)) {
                    queryParts.add('repo:' + input.repository);
                }

                // Add organization filter if specified
                if (String.isNotBlank(input.organization)) {
                    queryParts.add('org:' + input.organization);
                }

                // Add language filter if specified
                if (String.isNotBlank(input.language)) {
                    queryParts.add('language:' + input.language);
                }

                // Add search location filter if specified
                if (String.isNotBlank(input.search_in)) {
                    queryParts.add('in:' + input.search_in);
                }

                String query = String.join(queryParts, ' ');

                Http http = new Http();
                HttpRequest request = new HttpRequest();

                // Build the endpoint URL
                String endpoint = 'callout:GitHub_API/search/code?q=' +
                    EncodingUtil.urlEncode(query, 'UTF-8');

                if (input.per_page != null) {
                    endpoint += '&per_page=' + Math.min(input.per_page, 100);
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

                    List<Object> items = (List<Object>)searchResponse.get('items');

                    for (Object item : items) {
                        Map<String, Object> codeMap = (Map<String, Object>)item;
                        CodeSearchResult code = new CodeSearchResult();

                        code.name = (String)codeMap.get('name');
                        code.path = (String)codeMap.get('path');
                        code.sha = (String)codeMap.get('sha');
                        code.html_url = (String)codeMap.get('html_url');
                        code.raw_url = (String)codeMap.get('download_url');
                        code.git_url = (String)codeMap.get('git_url');
                        code.score = Double.valueOf(codeMap.get('score'));

                        // Get repository information
                        Map<String, Object> repoMap = (Map<String, Object>)codeMap.get('repository');
                        code.repository_full_name = (String)repoMap.get('full_name');

                        // Handle text matches if present
                        code.text_matches = new List<TextMatch>();
                        List<Object> matchesList = (List<Object>)codeMap.get('text_matches');
                        if (matchesList != null) {
                            for (Object matchObj : matchesList) {
                                Map<String, Object> matchMap = (Map<String, Object>)matchObj;
                                TextMatch match = new TextMatch();

                                match.object_type = (String)matchMap.get('object_type');
                                match.property = (String)matchMap.get('property');
                                match.fragment = (String)matchMap.get('fragment');

                                // Get the matching terms
                                match.matches = new List<String>();
                                List<Object> termsList = (List<Object>)matchMap.get('matches');
                                for (Object termObj : termsList) {
                                    Map<String, Object> termMap = (Map<String, Object>)termObj;
                                    match.matches.add((String)termMap.get('text'));
                                }

                                code.text_matches.add(match);
                            }
                        }

                        output.code_results.add(code);
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
