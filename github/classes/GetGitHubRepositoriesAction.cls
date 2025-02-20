public class GetGitHubRepositoriesAction {

    /**
     * Input class for the Agentforce action
     */
    public class GetRepositoriesInput {
        @InvocableVariable(required=true description='The organization name to get repositories for')
        public String org_name;

        @InvocableVariable(description='Type of repositories to return (all, public, private, forks, sources, member)')
        public String type;

        @InvocableVariable(description='How to sort the repositories (created, updated, pushed, full_name)')
        public String sort_by;

        @InvocableVariable(description='Direction of sort (asc or desc)')
        public String direction;
    }

    /**
     * Class representing a GitHub repository's essential properties
     */
    public class RepositoryInfo {
        @InvocableVariable(description='Repository ID')
        public String id;

        @InvocableVariable(description='Repository name')
        public String name;

        @InvocableVariable(description='Full repository name including owner')
        public String full_name;

        @InvocableVariable(description='Repository description')
        public String description;

        @InvocableVariable(description='Whether the repository is private')
        public Boolean is_private;

        @InvocableVariable(description='Repository HTML URL')
        public String html_url;

        @InvocableVariable(description='Default branch name')
        public String default_branch;

        @InvocableVariable(description='Created date')
        public DateTime created_at;

        @InvocableVariable(description='Last updated date')
        public DateTime updated_at;
    }

    /**
     * Output class containing repositories or error information
     */
    public class GetRepositoriesOutput {
        @InvocableVariable(description='List of repositories matching the criteria')
        public List<RepositoryInfo> repositories;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;

        public GetRepositoriesOutput() {
            repositories = new List<RepositoryInfo>();
        }
    }

    /**
     * Main invocable method for the Agentforce action
     */
    @InvocableMethod(label='Get GitHub Organization Repositories'
                     description='Retrieves repositories for a GitHub organization with optional filtering and sorting')
    public static List<GetRepositoriesOutput> getRepositories(List<GetRepositoriesInput> inputs) {
        List<GetRepositoriesOutput> outputs = new List<GetRepositoriesOutput>();

        for(GetRepositoriesInput input : inputs) {
            GetRepositoriesOutput output = new GetRepositoriesOutput();

            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();

                // Build the query string with parameters
                String endpoint = 'callout:GitHub_API/orgs/' + input.org_name + '/repos?';
                List<String> params = new List<String>();

                if (String.isNotBlank(input.type)) {
                    params.add('type=' + EncodingUtil.urlEncode(input.type, 'UTF-8'));
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
                    List<Object> reposData = (List<Object>)JSON.deserializeUntyped(response.getBody());

                    for (Object repoObj : reposData) {
                        Map<String, Object> repoMap = (Map<String, Object>)repoObj;
                        RepositoryInfo repo = new RepositoryInfo();

                        repo.id = String.valueOf(repoMap.get('id'));
                        repo.name = (String)repoMap.get('name');
                        repo.full_name = (String)repoMap.get('full_name');
                        repo.description = (String)repoMap.get('description');
                        repo.is_private = (Boolean)repoMap.get('private');
                        repo.html_url = (String)repoMap.get('html_url');
                        repo.default_branch = (String)repoMap.get('default_branch');

                        // Handle date conversions
                        String createdStr = (String)repoMap.get('created_at');
                        String updatedStr = (String)repoMap.get('updated_at');

                        if (String.isNotBlank(createdStr)) {
                            repo.created_at = DateTime.valueOfGmt(createdStr.replace('T', ' ').replace('Z', ' '));
                        }

                        if (String.isNotBlank(updatedStr)) {
                            repo.updated_at = DateTime.valueOfGmt(updatedStr.replace('T', ' ').replace('Z', ' '));
                        }

                        output.repositories.add(repo);
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
