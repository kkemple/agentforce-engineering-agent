public class CreateAsanaTaskAction {

    /**
     * Input class for the Flow action
     */
    public class TaskCreateInput {
        @InvocableVariable(required=true description='Name/title of the task')
        public String name;

        @InvocableVariable(description='Notes/description for the task')
        public String notes;

        @InvocableVariable(description='Due date for the task (YYYY-MM-DD)')
        public Date due_date;

        @InvocableVariable(required=true description='Workspace GID')
        public String workspace_gid;

        @InvocableVariable(description='Project GID to add the task to')
        public String project_gid;
    }

    /**
     * Output class containing created task details or error information
     */
    public class TaskCreateOutput {
        @InvocableVariable(description='GID of the created task')
        public String task_gid;

        @InvocableVariable(description='Name of the created task')
        public String task_name;

        @InvocableVariable(description='Permalink URL to the created task')
        public String permalink_url;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;
    }

    /**
     * Main invocable method for the Flow action
     * Creates a new task with the provided details
     */
    @InvocableMethod(label='Create Asana Task'
                     description='Creates a new task in Asana with specified details')
    public static List<TaskCreateOutput> createTask(List<TaskCreateInput> inputs) {
        List<TaskCreateOutput> outputs = new List<TaskCreateOutput>();

        for(TaskCreateInput input : inputs) {
            TaskCreateOutput output = new TaskCreateOutput();

            try {
                // Construct the request body
                Map<String, Object> taskData = new Map<String, Object>();
                taskData.put('name', input.name);
                taskData.put('workspace', input.workspace_gid);

                if (String.isNotBlank(input.notes)) {
                    taskData.put('notes', input.notes);
                }

                if (input.due_date != null) {
                    taskData.put('due_on', input.due_date.year() + '-' +
                               String.valueOf(input.due_date.month()).leftPad(2, '0') + '-' +
                               String.valueOf(input.due_date.day()).leftPad(2, '0'));
                }

                // Handle project assignment
                if (String.isNotBlank(input.project_gid)) {
                    taskData.put('projects', new List<String>{ input.project_gid });
                }

                Map<String, Object> requestBody = new Map<String, Object>();
                requestBody.put('data', taskData);

                // Make the POST request to create the task
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:Asana_API/tasks');
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                request.setBody(JSON.serialize(requestBody));

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 201) {
                    // Parse the response
                    Map<String, Object> asanaResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    Map<String, Object> data = (Map<String, Object>)asanaResponse.get('data');

                    output.task_gid = (String)data.get('gid');
                    output.task_name = (String)data.get('name');
                    output.permalink_url = (String)data.get('permalink_url');

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
