public class GetAsanaTasksByProjectSectionAction {

    /**
     * Input class for the Flow action
     */
    public class SectionTasksInput {
        @InvocableVariable(required=true description='The GID of the section to get tasks from')
        public String section_gid;
    }

    /**
     * Class representing an Asana task's properties
     */
    public class TaskInfo {
        @InvocableVariable(description='Task GID')
        public String gid;

        @InvocableVariable(description='Task name')
        public String name;

        @InvocableVariable(description='Due date of the task')
        public Date due_date;

        @InvocableVariable(description='Whether the task is completed')
        public Boolean completed;

        @InvocableVariable(description='Task description/notes')
        public String notes;

        @InvocableVariable(description='Permalink URL to the task')
        public String permalink_url;
    }

    /**
     * Output class containing task details or error information
     */
    public class SectionTasksOutput {
        @InvocableVariable(description='List of tasks found in the section')
        public List<TaskInfo> tasks;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;

        public SectionTasksOutput() {
            tasks = new List<TaskInfo>();
        }
    }

    /**
     * Main invocable method for the Flow action
     * Takes a section GID and returns all tasks in that section
     */
    @InvocableMethod(label='Get Asana Tasks By Project Section'
                     description='Retrieves all tasks from a specific section in an Asana project')
    public static List<SectionTasksOutput> getTasksBySection(List<SectionTasksInput> inputs) {
        List<SectionTasksOutput> outputs = new List<SectionTasksOutput>();

        for(SectionTasksInput input : inputs) {
            SectionTasksOutput output = new SectionTasksOutput();

            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:Asana_API/sections/' + input.section_gid +
                                 '/tasks?opt_fields=gid,name,due_on,completed,notes,permalink_url');
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
                        task.completed = (Boolean)taskMap.get('completed');
                        task.notes = (String)taskMap.get('notes');
                        task.permalink_url = (String)taskMap.get('permalink_url');

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
