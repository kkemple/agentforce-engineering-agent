public class DeleteAsanaTaskAction {

    /**
     * Input class for the Flow action
     */
    public class TaskDeleteInput {
        @InvocableVariable(required=true description='GID of the task to delete')
        public String task_gid;
    }

    /**
     * Output class containing success/error information
     */
    public class TaskDeleteOutput {
        @InvocableVariable(description='Whether the task was successfully deleted')
        public Boolean success;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;
    }

    /**
     * Main invocable method for the Flow action
     * Deletes a specific Asana task
     */
    @InvocableMethod(label='Delete Asana Task'
                     description='Permanently deletes an Asana task')
    public static List<TaskDeleteOutput> deleteTask(List<TaskDeleteInput> inputs) {
        List<TaskDeleteOutput> outputs = new List<TaskDeleteOutput>();

        for(TaskDeleteInput input : inputs) {
            TaskDeleteOutput output = new TaskDeleteOutput();

            try {
                // Make the DELETE request
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:Asana_API/tasks/' + input.task_gid);
                request.setMethod('DELETE');

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 200) {
                    output.success = true;
                } else {
                    output.success = false;
                    output.error_message = 'Failed with status code: ' + response.getStatusCode();
                    System.debug('Error response: ' + response.getBody());
                }

            } catch(Exception e) {
                output.success = false;
                output.error_message = 'Error: ' + e.getMessage();
                System.debug('Error details: ' + e.getStackTraceString());
            }

            outputs.add(output);
        }

        return outputs;
    }
}
