public class SearchAsanaTasksByWorkspaceAction {

    /**
     * Input class for the Agentforce action
     */
    public class SearchTasksInput {
        @InvocableVariable(required=true description='The GID of the workspace to search in')
        public String workspace_gid;

        @InvocableVariable(description='Optional project GID to filter tasks')
        public String projects_gid;

        @InvocableVariable(description='Text to search for in task name and description')
        public String text;
    }

    /**
     * Class representing an Asana task's essential properties
     */
    public class TaskInfo {
        @InvocableVariable(description='Task GID')
        public String gid;

        @InvocableVariable(description='Task name')
        public String name;

        @InvocableVariable(description='Task description/notes')
        public String notes;

        @InvocableVariable(description='Permalink URL to the task')
        public String permalink_url;

        @InvocableVariable(description='Whether the task is completed')
        public Boolean completed;

        @InvocableVariable(description='Due date of the task')
        public Date due_date;
    }

    /**
     * Output class containing search results or error information
     */
    public class SearchTasksOutput {
        @InvocableVariable(description='List of tasks matching the search criteria')
        public List<TaskInfo> tasks;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;

        public SearchTasksOutput() {
            tasks = new List<TaskInfo>();
        }
    }

    /**
     * Main invocable method for the Agentforce action
     */
    @InvocableMethod(label='Search Asana Tasks By Workspace'
                     description='Searches for tasks in an Asana workspace with optional project filter and text search')
    public static List<SearchTasksOutput> searchTasks(List<SearchTasksInput> inputs) {
        List<SearchTasksOutput> outputs = new List<SearchTasksOutput>();

        for(SearchTasksInput input : inputs) {
            SearchTasksOutput output = new SearchTasksOutput();

            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();

                // Build the query string with search parameters
                String endpoint = 'callout:Asana_API/workspaces/' + input.workspace_gid + '/tasks/search?';
                List<String> params = new List<String>();

                // Add the required opt_fields for the response
                params.add('opt_fields=gid,name,notes,permalink_url,completed,due_on');

                // Add search parameters if provided
                if (String.isNotBlank(input.text)) {
                    params.add('text=' + EncodingUtil.urlEncode(input.text, 'UTF-8'));
                }

                if (String.isNotBlank(input.projects_gid)) {
                    params.add('projects.any=' + input.projects_gid);
                }

                endpoint += String.join(params, '&');
                request.setEndpoint(endpoint);
                request.setMethod('GET');

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 200) {
                    Map<String, Object> asanaResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    List<Object> tasksData = (List<Object>)asanaResponse.get('data');

                    for (Object taskObj : tasksData) {
                        Map<String, Object> taskMap = (Map<String, Object>)taskObj;
                        TaskInfo task = new TaskInfo();

                        task.gid = (String)taskMap.get('gid');
                        task.name = (String)taskMap.get('name');
                        task.notes = (String)taskMap.get('notes');
                        task.permalink_url = (String)taskMap.get('permalink_url');
                        task.completed = (Boolean)taskMap.get('completed');

                        // Handle due date conversion
                        String dueOnStr = (String)taskMap.get('due_on');
                        if (String.isNotBlank(dueOnStr)) {
                            task.due_date = Date.valueOf(dueOnStr);
                        }

                        output.tasks.add(task);
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
