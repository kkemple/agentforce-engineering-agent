public class GetAsanaTaskAction {
    /**
     * Input class for the Agentforce action
     */
    public class GetTaskInput {
        @InvocableVariable(required=true description='The GID of the task to retrieve')
        public String task_gid;
    }

    /**
 * Output class containing task details or error information
 */
    public class GetTaskOutput {
        @InvocableVariable(description='Detailed task information')
        public TaskInfo task;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;
    }

    /**
     * Class representing an Asana task's detailed properties
     */
    public class TaskInfo {
        // Basic Task Info
        @InvocableVariable(description='Task GID')
        public String gid;

        @InvocableVariable(description='Task name')
        public String name;

        @InvocableVariable(description='Task description/notes')
        public String notes;

        @InvocableVariable(description='HTML formatted notes')
        public String html_notes;

        @InvocableVariable(description='Permalink URL to the task')
        public String permalink_url;

        @InvocableVariable(description='Resource type')
        public String resource_type;

        @InvocableVariable(description='Resource subtype')
        public String resource_subtype;

        // Status
        @InvocableVariable(description='Whether the task is completed')
        public Boolean completed;

        @InvocableVariable(description='Approval status')
        public String approval_status;

        @InvocableVariable(description='Assignee status')
        public String assignee_status;

        // Dates
        @InvocableVariable(description='The time at which the task was completed')
        public DateTime completed_at;

        @InvocableVariable(description='The time the task was created')
        public DateTime created_at;

        @InvocableVariable(description='The last time the task was modified')
        public DateTime modified_at;

        @InvocableVariable(description='Due date of the task')
        public Date due_on;

        @InvocableVariable(description='Due date and time of the task')
        public DateTime due_at;

        @InvocableVariable(description='Start date of the task')
        public Date start_on;

        @InvocableVariable(description='Start date and time of the task')
        public DateTime start_at;

        // Users
        @InvocableVariable(description='Name of the assigned user')
        public String assignee_name;

        @InvocableVariable(description='GID of the assigned user')
        public String assignee_gid;

        @InvocableVariable(description='Name of user who completed the task')
        public String completed_by_name;

        @InvocableVariable(description='Name of user who created the task')
        public String created_by_name;

        // Projects and Sections
        @InvocableVariable(description='List of project memberships')
        public List<ProjectInfo> projects;

        // Dependencies
        @InvocableVariable(description='Tasks this task depends on')
        public List<DependencyInfo> dependencies;

        @InvocableVariable(description='Tasks that depend on this task')
        public List<DependencyInfo> dependents;

        // Task Stats
        @InvocableVariable(description='Number of subtasks')
        public Integer num_subtasks;

        @InvocableVariable(description='Number of likes')
        public Integer num_likes;

        @InvocableVariable(description='Whether the current user has liked the task')
        public Boolean liked;

        // Tags and Custom Fields
        @InvocableVariable(description='List of tags')
        public List<TagInfo> tags;

        @InvocableVariable(description='List of custom field values')
        public List<CustomFieldValue> custom_fields;

        // Time Tracking
        @InvocableVariable(description='Total time spent on task in minutes')
        public Integer actual_time_minutes;
    }

    /**
     * Main invocable method for the Agentforce action
     */
    @InvocableMethod(label='Get Detailed Asana Task'
                     description='Retrieves comprehensive information about a single Asana task')
    public static List<GetTaskOutput> getTask(List<GetTaskInput> inputs) {
        List<GetTaskOutput> outputs = new List<GetTaskOutput>();

        for(GetTaskInput input : inputs) {
            GetTaskOutput output = new GetTaskOutput();

            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();

                // Request all relevant fields
                String endpoint = 'callout:Asana_API/tasks/' + input.task_gid + '?opt_fields=';
                List<String> fields = new List<String>{
                    'gid,name,notes,html_notes,permalink_url,resource_type,resource_subtype',
                    'completed,approval_status,assignee_status',
                    'completed_at,created_at,modified_at,due_on,due_at,start_on,start_at',
                    'assignee,assignee.name,completed_by,completed_by.name,created_by,created_by.name',
                    'memberships,memberships.project,memberships.project.name,memberships.section,memberships.section.name',
                    'dependencies,dependencies.name,dependents,dependents.name',
                    'num_subtasks,num_likes,liked',
                    'tags,tags.name',
                    'custom_fields.gid,custom_fields.name,custom_fields.type,custom_fields.enum_value,custom_fields.display_value,' +
                    'custom_fields.text_value,custom_fields.number_value,custom_fields.enum_value.color,custom_fields.enum_value.name',
                    'actual_time_minutes'
                };

                endpoint += String.join(fields, ',');
                request.setEndpoint(endpoint);
                request.setMethod('GET');

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 200) {
                    Map<String, Object> asanaResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    Map<String, Object> taskData = (Map<String, Object>)asanaResponse.get('data');
                    TaskInfo task = parseTaskData(taskData);
                    output.task = task;
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

    /**
     * Class representing a tag in Asana
     */
    public class TagInfo {
        @InvocableVariable(description='Tag GID')
        public String gid;

        @InvocableVariable(description='Tag name')
        public String name;
    }

    /**
     * Class representing project membership
     */
    public class ProjectInfo {
        @InvocableVariable(description='Project GID')
        public String gid;

        @InvocableVariable(description='Project name')
        public String name;

        @InvocableVariable(description='Section GID')
        public String section_gid;

        @InvocableVariable(description='Section name')
        public String section_name;
    }

    /**
     * Class representing custom field value
     */
    public class CustomFieldValue {
        @InvocableVariable(description='Custom field GID')
        public String gid;

        @InvocableVariable(description='Custom field name')
        public String name;

        @InvocableVariable(description='Custom field type')
        public String field_type;

        @InvocableVariable(description='Display value')
        public String display_value;

        @InvocableVariable(description='Raw value based on type (text, number, etc)')
        public String value;

        @InvocableVariable(description='Color for enum values')
        public String color;
    }

    /**
     * Class representing task dependencies
     */
    public class DependencyInfo {
        @InvocableVariable(description='GID of dependent/blocking task')
        public String gid;

        @InvocableVariable(description='Name of dependent/blocking task')
        public String name;
    }


    private static TaskInfo parseTaskData(Map<String, Object> taskData) {
        TaskInfo task = new TaskInfo();

        // Basic Task Info
        task.gid = (String)taskData.get('gid');
        task.name = (String)taskData.get('name');
        task.notes = (String)taskData.get('notes');
        task.html_notes = (String)taskData.get('html_notes');
        task.permalink_url = (String)taskData.get('permalink_url');
        task.resource_type = (String)taskData.get('resource_type');
        task.resource_subtype = (String)taskData.get('resource_subtype');

        // Status
        task.completed = (Boolean)taskData.get('completed');
        task.approval_status = (String)taskData.get('approval_status');
        task.assignee_status = (String)taskData.get('assignee_status');

        // Parse dates
        if (taskData.get('completed_at') != null) {
            task.completed_at = parseDateTime(String.valueOf(taskData.get('completed_at')));
        }
        if (taskData.get('created_at') != null) {
            task.created_at = parseDateTime(String.valueOf(taskData.get('created_at')));
        }
        if (taskData.get('modified_at') != null) {
            task.modified_at = parseDateTime(String.valueOf(taskData.get('modified_at')));
        }
        if (taskData.get('due_at') != null) {
            task.due_at = parseDateTime(String.valueOf(taskData.get('due_at')));
        }
        if (taskData.get('start_at') != null) {
            task.start_at = parseDateTime(String.valueOf(taskData.get('start_at')));
        }

        // Parse date-only fields
        String dueOnStr = (String)taskData.get('due_on');
        if (String.isNotBlank(dueOnStr)) {
            task.due_on = Date.valueOf(dueOnStr);
        }

        String startOnStr = (String)taskData.get('start_on');
        if (String.isNotBlank(startOnStr)) {
            task.start_on = Date.valueOf(startOnStr);
        }

        // Parse users
        if (taskData.get('assignee') != null) {
            Map<String, Object> assignee = (Map<String, Object>)taskData.get('assignee');
            task.assignee_name = (String)assignee.get('name');
            task.assignee_gid = (String)assignee.get('gid');
        }

        if (taskData.get('completed_by') != null) {
            Map<String, Object> completedBy = (Map<String, Object>)taskData.get('completed_by');
            task.completed_by_name = (String)completedBy.get('name');
        }

        if (taskData.get('created_by') != null) {
            Map<String, Object> createdBy = (Map<String, Object>)taskData.get('created_by');
            task.created_by_name = (String)createdBy.get('name');
        }

        // Parse memberships (projects and sections)
        if (taskData.get('memberships') != null) {
            List<Object> memberships = (List<Object>)taskData.get('memberships');
            task.projects = new List<ProjectInfo>();

            for (Object mem : memberships) {
                Map<String, Object> membership = (Map<String, Object>)mem;
                ProjectInfo proj = new ProjectInfo();

                if (membership.get('project') != null) {
                    Map<String, Object> project = (Map<String, Object>)membership.get('project');
                    proj.gid = (String)project.get('gid');
                    proj.name = (String)project.get('name');
                }

                if (membership.get('section') != null) {
                    Map<String, Object> section = (Map<String, Object>)membership.get('section');
                    proj.section_gid = (String)section.get('gid');
                    proj.section_name = (String)section.get('name');
                }

                task.projects.add(proj);
            }
        }

        // Parse dependencies
        if (taskData.get('dependencies') != null) {
            List<Object> deps = (List<Object>)taskData.get('dependencies');
            task.dependencies = new List<DependencyInfo>();

            for (Object dep : deps) {
                Map<String, Object> depMap = (Map<String, Object>)dep;
                DependencyInfo depInfo = new DependencyInfo();
                depInfo.gid = (String)depMap.get('gid');
                depInfo.name = (String)depMap.get('name');
                task.dependencies.add(depInfo);
            }
        }

        if (taskData.get('dependents') != null) {
            List<Object> deps = (List<Object>)taskData.get('dependents');
            task.dependents = new List<DependencyInfo>();

            for (Object dep : deps) {
                Map<String, Object> depMap = (Map<String, Object>)dep;
                DependencyInfo depInfo = new DependencyInfo();
                depInfo.gid = (String)depMap.get('gid');
                depInfo.name = (String)depMap.get('name');
                task.dependents.add(depInfo);
            }
        }

        // Task Stats
        task.num_subtasks = (Integer)taskData.get('num_subtasks');
        task.num_likes = (Integer)taskData.get('num_likes');
        task.liked = (Boolean)taskData.get('liked');

        // Parse tags
        if (taskData.get('tags') != null) {
            List<Object> tagsData = (List<Object>)taskData.get('tags');
            task.tags = new List<TagInfo>();

            for (Object t : tagsData) {
                Map<String, Object> tagMap = (Map<String, Object>)t;
                TagInfo tag = new TagInfo();
                tag.gid = (String)tagMap.get('gid');
                tag.name = (String)tagMap.get('name');
                task.tags.add(tag);
            }
        }

        // Parse custom fields
        if (taskData.get('custom_fields') != null) {
            List<Object> fields = (List<Object>)taskData.get('custom_fields');
            task.custom_fields = new List<CustomFieldValue>();

            for (Object f : fields) {
                Map<String, Object> fieldMap = (Map<String, Object>)f;
                CustomFieldValue field = new CustomFieldValue();
                field.gid = (String)fieldMap.get('gid');
                field.name = (String)fieldMap.get('name');
                field.field_type = (String)fieldMap.get('type');
                field.display_value = (String)fieldMap.get('display_value');

                // Handle different field types
                String fieldType = (String)fieldMap.get('type');
                if (fieldType == 'text') {
                    field.value = (String)fieldMap.get('text_value');
                } else if (fieldType == 'number') {
                    Object numValue = fieldMap.get('number_value');
                    field.value = numValue != null ? String.valueOf(numValue) : null;
                } else if (fieldType == 'enum') {
                    Map<String, Object> enumValue = (Map<String, Object>)fieldMap.get('enum_value');
                    if (enumValue != null) {
                        field.value = (String)enumValue.get('name');
                        field.color = (String)enumValue.get('color');
                    }
                }

                task.custom_fields.add(field);
            }
        }

        task.actual_time_minutes = (Integer)taskData.get('actual_time_minutes');

        return task;
    }

    private static DateTime parseDateTime(String dtString) {
        if (String.isBlank(dtString)) return null;
        return (DateTime)JSON.deserialize('"' + dtString + '"', DateTime.class);
    }
}
