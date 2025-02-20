public class CreateGitHubCodespaceFromPRAction {

    /**
     * Input class for the Agentforce action
     */
    public class CreateCodespaceInput {
        @InvocableVariable(required=true description='The owner of the repository')
        public String owner;

        @InvocableVariable(required=true description='The name of the repository')
        public String repo;

        @InvocableVariable(required=true description='The pull request number')
        public Integer pull_number;

        @InvocableVariable(description='The machine type to use for the codespace')
        public String machine;

        @InvocableVariable(description='Location for the codespace')
        public String location;

        @InvocableVariable(description='Idle timeout in minutes')
        public Integer idle_timeout_minutes;
    }

    /**
     * Class representing a created GitHub codespace
     */
    public class CodespaceInfo {
        @InvocableVariable(description='Codespace ID')
        public String id;

        @InvocableVariable(description='Codespace name')
        public String name;

        @InvocableVariable(description='State of the codespace')
        public String state;

        @InvocableVariable(description='URL to access the codespace')
        public String web_url;

        @InvocableVariable(description='Machine type used')
        public String machine_type;

        @InvocableVariable(description='Location of the codespace')
        public String location;

        @InvocableVariable(description='Created date')
        public DateTime created_at;

        @InvocableVariable(description='Last used date')
        public DateTime last_used_at;

        @InvocableVariable(description='Idle timeout in minutes')
        public Integer idle_timeout_minutes;
    }

    /**
     * Output class containing codespace information or error information
     */
    public class CreateCodespaceOutput {
        @InvocableVariable(description='Information about the created codespace')
        public CodespaceInfo codespace;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;
    }

    /**
     * Main invocable method for the Agentforce action
     */
    @InvocableMethod(label='Create GitHub Codespace from Pull Request'
                     description='Creates a new codespace from a pull request in a GitHub repository')
    public static List<CreateCodespaceOutput> createCodespace(List<CreateCodespaceInput> inputs) {
        List<CreateCodespaceOutput> outputs = new List<CreateCodespaceOutput>();

        for(CreateCodespaceInput input : inputs) {
            CreateCodespaceOutput output = new CreateCodespaceOutput();

            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();

                String endpoint = 'callout:GitHub_API/repos/' + input.owner + '/' + input.repo + '/codespaces';
                request.setEndpoint(endpoint);
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');

                // Build the request body
                Map<String, Object> bodyMap = new Map<String, Object>();
                bodyMap.put('pull_request', input.pull_number);

                if (String.isNotBlank(input.machine)) {
                    bodyMap.put('machine', input.machine);
                }

                if (String.isNotBlank(input.location)) {
                    bodyMap.put('location', input.location);
                }

                if (input.idle_timeout_minutes != null) {
                    bodyMap.put('idle_timeout_minutes', input.idle_timeout_minutes);
                }

                request.setBody(JSON.serialize(bodyMap));

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 201) {
                    Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    CodespaceInfo codespace = new CodespaceInfo();

                    codespace.id = String.valueOf(responseData.get('id'));
                    codespace.name = (String)responseData.get('name');
                    codespace.state = (String)responseData.get('state');
                    codespace.web_url = (String)responseData.get('web_url');

                    // Get machine info
                    Map<String, Object> machine = (Map<String, Object>)responseData.get('machine');
                    codespace.machine_type = (String)machine.get('name');

                    codespace.location = (String)responseData.get('location');
                    codespace.idle_timeout_minutes = Integer.valueOf(responseData.get('idle_timeout_minutes'));

                    // Handle date conversions
                    String createdStr = (String)responseData.get('created_at');
                    String lastUsedStr = (String)responseData.get('last_used_at');

                    if (String.isNotBlank(createdStr)) {
                        codespace.created_at = DateTime.valueOfGmt(createdStr.replace('T', ' ').replace('Z', ' '));
                    }

                    if (String.isNotBlank(lastUsedStr)) {
                        codespace.last_used_at = DateTime.valueOfGmt(lastUsedStr.replace('T', ' ').replace('Z', ' '));
                    }

                    output.codespace = codespace;
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
