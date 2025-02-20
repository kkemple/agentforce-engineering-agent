public class GetAsanaWorkspacesAction {

    /**
     * Class representing an Asana workspace's properties
     */
    public class WorkspaceInfo {
        @InvocableVariable(description='Workspace GID')
        public String gid;

        @InvocableVariable(description='Workspace name')
        public String name;

        @InvocableVariable(description='Whether the workspace is an organization')
        public Boolean is_organization;
    }

    /**
     * Output class containing workspace details or error information
     */
    public class WorkspacesOutput {
        @InvocableVariable(description='List of workspaces found')
        public List<WorkspaceInfo> workspaces;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;

        public WorkspacesOutput() {
            workspaces = new List<WorkspaceInfo>();
        }
    }

    /**
     * Main invocable method for the Flow action
     * Returns all workspaces accessible to the authenticated user
     */
    @InvocableMethod(label='Get Asana Workspaces'
                     description='Retrieves all accessible Asana workspaces')
    public static List<WorkspacesOutput> getWorkspaces(List<List<String>> inputs) {
        List<WorkspacesOutput> outputs = new List<WorkspacesOutput>();
        WorkspacesOutput output = new WorkspacesOutput();

        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Asana_API/workspaces?opt_fields=gid,name,is_organization');
            request.setMethod('GET');

            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                Map<String, Object> asanaResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                List<Object> workspacesData = (List<Object>)asanaResponse.get('data');

                for (Object workspaceObj : workspacesData) {
                    Map<String, Object> workspaceMap = (Map<String, Object>)workspaceObj;
                    WorkspaceInfo workspace = new WorkspaceInfo();

                    workspace.gid = (String)workspaceMap.get('gid');
                    workspace.name = (String)workspaceMap.get('name');
                    workspace.is_organization = (Boolean)workspaceMap.get('is_organization');

                    output.workspaces.add(workspace);
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
        return outputs;
    }
}
