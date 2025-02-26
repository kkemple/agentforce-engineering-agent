public class GetAsanaTagsByWorkspaceAction {

    /**
     * Input class for the Flow action
     * Requires workspace GID to fetch tags
     */
    public class WorkspaceTagsInput {
        @InvocableVariable(required=true description='The GID of the workspace to get tags from')
        public String workspace_gid;
    }

    /**
     * Class representing an Asana tag's properties
     */
    public class TagInfo {
        @InvocableVariable(description='Tag GID')
        public String gid;

        @InvocableVariable(description='Tag name')
        public String name;

        @InvocableVariable(description='Tag color')
        public String color;
    }

    /**
     * Output class containing tag details or error information
     */
    public class WorkspaceTagsOutput {
        @InvocableVariable(description='List of tags found in the workspace')
        public List<TagInfo> tags;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;

        public WorkspaceTagsOutput() {
            tags = new List<TagInfo>();
        }
    }

    /**
     * Main invocable method for the Flow action
     * Takes a workspace GID and returns all tags in that workspace
     */
    @InvocableMethod(label='Get Asana Tags By Workspace'
                     description='Retrieves all tags from a specific Asana workspace')
    public static List<WorkspaceTagsOutput> getWorkspaceTags(List<WorkspaceTagsInput> inputs) {
        List<WorkspaceTagsOutput> outputs = new List<WorkspaceTagsOutput>();

        for(WorkspaceTagsInput input : inputs) {
            WorkspaceTagsOutput output = new WorkspaceTagsOutput();

            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:Asana_API/workspaces/' + input.workspace_gid +
                                 '/tags?opt_fields=gid,name,color');
                request.setMethod('GET');

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 200) {
                    Map<String, Object> asanaResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    List<Object> tagsData = (List<Object>)asanaResponse.get('data');

                    for (Object tagObj : tagsData) {
                        Map<String, Object> tagMap = (Map<String, Object>)tagObj;
                        TagInfo tag = new TagInfo();

                        tag.gid = (String)tagMap.get('gid');
                        tag.name = (String)tagMap.get('name');
                        tag.color = (String)tagMap.get('color');

                        output.tags.add(tag);
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
