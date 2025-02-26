public class GetAsanaProjectsByWorkspaceAction {

    /**
     * Input class for the Flow action
     * Requires workspace GID to fetch projects
     */
    public class WorkspaceProjectsInput {
        @InvocableVariable(required=true description='The GID of the workspace to get projects from')
        public String workspace_gid;
    }

    /**
     * Class representing an Asana project's properties
     */
    public class ProjectInfo {
        @InvocableVariable(description='Project GID')
        public String gid;

        @InvocableVariable(description='Project name')
        public String name;

        @InvocableVariable(description='Project notes/description')
        public String notes;

        @InvocableVariable(description='Project color')
        public String color;

        @InvocableVariable(description='Whether the project is archived')
        public Boolean archived;

        @InvocableVariable(description='Public/private visibility')
        public Boolean public_status;

        @InvocableVariable(description='Project layout (list, board, timeline, etc)')
        public String layout;

        @InvocableVariable(description='Current project status')
        public String current_status;

        @InvocableVariable(description='Project due date')
        public Date due_date;

        @InvocableVariable(description='Project start date')
        public Date start_date;

        @InvocableVariable(description='URL to view the project')
        public String permalink_url;
    }

    /**
     * Output class containing project details or error information
     */
    public class WorkspaceProjectsOutput {
        @InvocableVariable(description='List of projects found in the workspace')
        public List<ProjectInfo> projects;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;

        public WorkspaceProjectsOutput() {
            projects = new List<ProjectInfo>();
        }
    }

    /**
     * Main invocable method for the Flow action
     * Takes a workspace GID and returns all projects in that workspace
     */
    @InvocableMethod(label='Get Asana Projects By Workspace'
                     description='Retrieves all projects from a specific Asana workspace')
    public static List<WorkspaceProjectsOutput> getWorkspaceProjects(List<WorkspaceProjectsInput> inputs) {
        List<WorkspaceProjectsOutput> outputs = new List<WorkspaceProjectsOutput>();

        for(WorkspaceProjectsInput input : inputs) {
            WorkspaceProjectsOutput output = new WorkspaceProjectsOutput();

            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:Asana_API/workspaces/' + input.workspace_gid +
                                 '/projects?opt_fields=gid,name,notes,color,archived,public,layout,' +
                                 'current_status,due_date,start_date,permalink_url');
                request.setMethod('GET');

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 200) {
                    Map<String, Object> asanaResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    List<Object> projectsData = (List<Object>)asanaResponse.get('data');

                    for (Object projectObj : projectsData) {
                        Map<String, Object> projectMap = (Map<String, Object>)projectObj;
                        ProjectInfo project = new ProjectInfo();

                        project.gid = (String)projectMap.get('gid');
                        project.name = (String)projectMap.get('name');
                        project.notes = (String)projectMap.get('notes');
                        project.color = (String)projectMap.get('color');
                        project.archived = (Boolean)projectMap.get('archived');
                        project.public_status = (Boolean)projectMap.get('public');
                        project.layout = (String)projectMap.get('layout');
                        project.permalink_url = (String)projectMap.get('permalink_url');

                        // Handle current status if present
                        Map<String, Object> statusMap = (Map<String, Object>)projectMap.get('current_status');
                        if (statusMap != null) {
                            project.current_status = (String)statusMap.get('text');
                        }

                        // Handle dates (converting from string to Date)
                        String dueDateStr = (String)projectMap.get('due_date');
                        if (String.isNotBlank(dueDateStr)) {
                            project.due_date = Date.valueOf(dueDateStr);
                        }

                        String startDateStr = (String)projectMap.get('start_date');
                        if (String.isNotBlank(startDateStr)) {
                            project.start_date = Date.valueOf(startDateStr);
                        }

                        output.projects.add(project);
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
