public class GetAsanaTasksByTagAction {

    /**
     * Input class for the Flow action
     * Requires tag GID to fetch associated tasks
     */
    public class TagTasksInput {
        @InvocableVariable(required=true description='The GID of the tag to get tasks from')
        public String tag_gid;
    }

    /**
     * Class representing a tag
     */
    public class TagInfo {
        @InvocableVariable(description='Tag GID')
        public String gid;

        @InvocableVariable(description='Tag name')
        public String name;
    }

    /**
     * Class representing an Asana task's key properties
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

        @InvocableVariable(description='Tags associated with the task')
        public List<TagInfo> tags;

        public TaskInfo() {
            tags = new List<TagInfo>();
        }
    }

    /**
     * Output class containing task details or error information
     */
    public class TagTasksOutput {
        @InvocableVariable(description='List of tasks found with the tag')
        public List<TaskInfo> tasks;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;

        public TagTasksOutput() {
            tasks = new List<TaskInfo>();
        }
    }

    /**
     * Main invocable method for the Flow action
     * Takes a tag GID and returns all associated tasks
     */
    @InvocableMethod(label='Get Asana Tasks From Tag'
                     description='Retrieves all tasks associated with a specific Asana tag')
    public static List<TagTasksOutput> getTasksFromTag(List<TagTasksInput> inputs) {
        List<TagTasksOutput> outputs = new List<TagTasksOutput>();

        for(TagTasksInput input : inputs) {
            TagTasksOutput output = new TagTasksOutput();

            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                // Add tags to opt_fields
                request.setEndpoint('callout:Asana_API/tags/' + input.tag_gid +
                                 '/tasks?opt_fields=gid,name,due_on,completed,notes,permalink_url,tags.name,tags.gid');
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

                        // Process tags
                        List<Object> tagsData = (List<Object>)taskMap.get('tags');
                        if (tagsData != null) {
                            for (Object tagObj : tagsData) {
                                Map<String, Object> tagMap = (Map<String, Object>)tagObj;
                                TagInfo tag = new TagInfo();
                                tag.gid = (String)tagMap.get('gid');
                                tag.name = (String)tagMap.get('name');
                                task.tags.add(tag);
                            }
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
