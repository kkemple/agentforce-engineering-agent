public class GetAsanaSectionsByProjectAction {

    /**
     * Input class for the Flow action
     * Requires project GID to fetch sections
     */
    public class ProjectSectionsInput {
        @InvocableVariable(required=true description='The GID of the project to get sections from')
        public String project_gid;
    }

    /**
     * Class representing an Asana section's properties
     */
    public class SectionInfo {
        @InvocableVariable(description='Section GID')
        public String gid;

        @InvocableVariable(description='Section name')
        public String name;

        @InvocableVariable(description='Resource type (always "section")')
        public String resource_type;

        @InvocableVariable(description='Number of tasks in this section')
        public Integer num_tasks;
    }

    /**
     * Output class containing section details or error information
     */
    public class ProjectSectionsOutput {
        @InvocableVariable(description='List of sections found in the project')
        public List<SectionInfo> sections;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;

        public ProjectSectionsOutput() {
            sections = new List<SectionInfo>();
        }
    }

    /**
     * Main invocable method for the Flow action
     * Takes a project GID and returns all sections in that project
     */
    @InvocableMethod(label='Get Asana Sections By Project'
                     description='Retrieves all sections from a specific Asana project')
    public static List<ProjectSectionsOutput> getProjectSections(List<ProjectSectionsInput> inputs) {
        List<ProjectSectionsOutput> outputs = new List<ProjectSectionsOutput>();

        for(ProjectSectionsInput input : inputs) {
            ProjectSectionsOutput output = new ProjectSectionsOutput();

            try {
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:Asana_API/projects/' + input.project_gid +
                                 '/sections?opt_fields=gid,name,resource_type,num_tasks');
                request.setMethod('GET');

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 200) {
                    Map<String, Object> asanaResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    List<Object> sectionsData = (List<Object>)asanaResponse.get('data');

                    for (Object sectionObj : sectionsData) {
                        Map<String, Object> sectionMap = (Map<String, Object>)sectionObj;
                        SectionInfo section = new SectionInfo();

                        section.gid = (String)sectionMap.get('gid');
                        section.name = (String)sectionMap.get('name');
                        section.resource_type = (String)sectionMap.get('resource_type');

                        // Handle num_tasks which might be null
                        Object numTasksObj = sectionMap.get('num_tasks');
                        if (numTasksObj != null) {
                            section.num_tasks = Integer.valueOf(numTasksObj);
                        }

                        output.sections.add(section);
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
