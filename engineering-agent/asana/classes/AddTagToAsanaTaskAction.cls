public class AddTagToAsanaTaskAction {

    /**
     * Input class for the Flow action
     */
    public class TaskTagInput {
        @InvocableVariable(required=true description='GID of the task to add the tag to')
        public String task_gid;

        @InvocableVariable(required=true description='GID of the tag to add')
        public String tag_gid;
    }

    /**
     * Output class containing success/error information
     */
    public class TaskTagOutput {
        @InvocableVariable(description='Whether the tag was successfully added')
        public Boolean success;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;
    }

    /**
     * Main invocable method for the Flow action
     * Adds a tag to a specific Asana task
     */
    @InvocableMethod(label='Add Tag to Asana Task'
                     description='Adds a specified tag to an Asana task')
    public static List<TaskTagOutput> addTag(List<TaskTagInput> inputs) {
        List<TaskTagOutput> outputs = new List<TaskTagOutput>();

        for(TaskTagInput input : inputs) {
            TaskTagOutput output = new TaskTagOutput();

            try {
                // Construct the request body
                Map<String, Object> requestData = new Map<String, Object>();
                requestData.put('tag', input.tag_gid);

                Map<String, Object> requestBody = new Map<String, Object>();
                requestBody.put('data', requestData);

                // Make the POST request to add the tag
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:Asana_API/tasks/' + input.task_gid + '/addTag');
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');
                request.setBody(JSON.serialize(requestBody));

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
