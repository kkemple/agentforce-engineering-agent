public class UpdateAsanaTaskAction {

    /**
     * Input class for the Flow action
     */
    public class TaskUpdateInput {
        @InvocableVariable(required=true description='GID of the task to update')
        public String task_gid;

        @InvocableVariable(description='New name for the task')
        public String name;

        @InvocableVariable(description='New notes/description for the task')
        public String notes;

        @InvocableVariable(description='New due date for the task (YYYY-MM-DD)')
        public Date due_date;

        @InvocableVariable(description='Whether to mark the task as completed')
        public Boolean completed;

        @InvocableVariable(description='Project GID to add the task to')
        public String project_gid;
    }

    /**
     * Output class containing updated task details or error information
     */
    public class TaskUpdateOutput {
        @InvocableVariable(description='GID of the updated task')
        public String task_gid;

        @InvocableVariable(description='Name of the updated task')
        public String task_name;

        @InvocableVariable(description='Permalink URL to the task')
        public String permalink_url;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;
    }

    /**
     * Main invocable method for the Flow action
     * Updates an existing task with new details
     */
    @InvocableMethod(label='Update Asana Task'
                     description='Updates an existing Asana task with new details')
    public static List<TaskUpdateOutput> updateTask(List<TaskUpdateInput> inputs) {
        List<TaskUpdateOutput> outputs = new List<TaskUpdateOutput>();

        for(TaskUpdateInput input : inputs) {
            TaskUpdateOutput output = new TaskUpdateOutput();

            try {
                // Construct the request body with only the fields that are provided
                Map<String, Object> taskData = new Map<String, Object>();

                if (String.isNotBlank(input.name)) {
                    taskData.put('name', input.name);
                }

                if (String.isNotBlank(input.notes)) {
                    taskData.put('notes', input.notes);
                }

                if (input.due_date != null) {
                    taskData.put('due_on', input.due_date.year() + '-' +
                               String.valueOf(input.due_date.month()).leftPad(2, '0') + '-' +
                               String.valueOf(input.due_date.day()).leftPad(2, '0'));
                }

                if (input.completed != null) {
                    taskData.put('completed', input.completed);
                }

                if (String.isNotBlank(input.project_gid)) {
                    taskData.put('projects', new List<String>{ input.project_gid });
                }

                Map<String, Object> requestBody = new Map<String, Object>();
                requestBody.put('data', taskData);

                // Make the PUT request to update the task
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:Asana_API/tasks/' + input.task_gid);
                request.setMethod('PUT');
                request.setHeader('Content-Type', 'application/json');
                request.setBody(JSON.serialize(requestBody));

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 200) {
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
