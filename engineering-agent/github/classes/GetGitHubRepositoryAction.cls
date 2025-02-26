public class GetGitHubRepositoryAction {

    /**
     * Input class for the Agentforce action
     */
    public class GetRepositoryInput {
        @InvocableVariable(required=true description='The owner of the repository')
        public String owner;

        @InvocableVariable(required=true description='The name of the repository')
        public String repo;
    }

    /**
     * Class representing detailed GitHub repository information
     */
    public class RepositoryDetail {
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

        @InvocableVariable(description='Git clone URL')
        public String clone_url;

        @InvocableVariable(description='Default branch name')
        public String default_branch;

        @InvocableVariable(description='Number of open issues')
        public Integer open_issues_count;

        @InvocableVariable(description='Number of forks')
        public Integer forks_count;

        @InvocableVariable(description='Number of watchers')
        public Integer watchers_count;

        @InvocableVariable(description='Primary language')
        public String language;

        @InvocableVariable(description='Whether the repository has issues enabled')
        public Boolean has_issues;

        @InvocableVariable(description='Whether the repository is archived')
        public Boolean archived;

        @InvocableVariable(description='Created date')
        public DateTime created_at;

        @InvocableVariable(description='Last updated date')
        public DateTime updated_at;

        @InvocableVariable(description='Last pushed date')
        public DateTime pushed_at;
    }

    /**
     * Output class containing repository details or error information
     */
    public class GetRepositoryOutput {
        @InvocableVariable(description='Detailed repository information')
        public RepositoryDetail repository;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;
    }

    /**
     * Main invocable method for the Agentforce action
     */
    @InvocableMethod(label='Get GitHub Repository Details'
                     description='Retrieves detailed information about a specific GitHub repository')
    public static List<GetRepositoryOutput> getRepository(List<GetRepositoryInput> inputs) {
        List<GetRepositoryOutput> outputs = new List<GetRepositoryOutput>();

        for(GetRepositoryInput input : inputs) {
            GetRepositoryOutput output = new GetRepositoryOutput();

            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();

                String endpoint = 'callout:GitHub_API/repos/' + input.owner + '/' + input.repo;
                request.setEndpoint(endpoint);
                request.setMethod('GET');

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 200) {
                    Map<String, Object> repoData = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    RepositoryDetail repo = new RepositoryDetail();

                    repo.id = String.valueOf(repoData.get('id'));
                    repo.name = (String)repoData.get('name');
                    repo.full_name = (String)repoData.get('full_name');
                    repo.description = (String)repoData.get('description');
                    repo.is_private = (Boolean)repoData.get('private');
                    repo.html_url = (String)repoData.get('html_url');
                    repo.clone_url = (String)repoData.get('clone_url');
                    repo.default_branch = (String)repoData.get('default_branch');
                    repo.language = (String)repoData.get('language');
                    repo.has_issues = (Boolean)repoData.get('has_issues');
                    repo.archived = (Boolean)repoData.get('archived');

                    // Handle numeric values
                    repo.open_issues_count = Integer.valueOf(repoData.get('open_issues_count'));
                    repo.forks_count = Integer.valueOf(repoData.get('forks_count'));
                    repo.watchers_count = Integer.valueOf(repoData.get('watchers_count'));

                    // Handle date conversions
                    String createdStr = (String)repoData.get('created_at');
                    String updatedStr = (String)repoData.get('updated_at');
                    String pushedStr = (String)repoData.get('pushed_at');

                    if (String.isNotBlank(createdStr)) {
                        repo.created_at = DateTime.valueOfGmt(createdStr.replace('T', ' ').replace('Z', ' '));
                    }

                    if (String.isNotBlank(updatedStr)) {
                        repo.updated_at = DateTime.valueOfGmt(updatedStr.replace('T', ' ').replace('Z', ' '));
                    }

                    if (String.isNotBlank(pushedStr)) {
                        repo.pushed_at = DateTime.valueOfGmt(pushedStr.replace('T', ' ').replace('Z', ' '));
                    }

                    output.repository = repo;
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
