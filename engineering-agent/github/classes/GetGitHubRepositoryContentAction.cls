public class GetGitHubRepositoryContentAction {

    /**
     * Input class that defines the parameters needed to retrieve content from a GitHub repository.
     * This class captures the essential information needed to locate specific content within a repo.
     */
    public class GetContentInput {
        @InvocableVariable(required=true description='The owner of the repository')
        public String owner;

        @InvocableVariable(required=true description='The name of the repository')
        public String repo;

        @InvocableVariable(required=true description='The path to the content in the repository')
        public String path;

        @InvocableVariable(description='The name of the commit/branch/tag. Default: the repository\'s default branch')
        public String ref;
    }

    /**
     * Class representing detailed information about a content item from GitHub.
     * This can represent either a file or a directory entry.
     */
    public class ContentInfo {
        @InvocableVariable(description='Type of content (file, dir, symlink, submodule)')
        public String type;

        @InvocableVariable(description='Size of the file in bytes')
        public Long size;

        @InvocableVariable(description='Name of the file or directory')
        public String name;

        @InvocableVariable(description='Path to the content')
        public String path;

        @InvocableVariable(description='Content of the file (decoded if it\'s a file)')
        public String content;

        @InvocableVariable(description='SHA hash of the content')
        public String sha;

        @InvocableVariable(description='URL to view the content in GitHub')
        public String html_url;

        @InvocableVariable(description='URL to download the raw content')
        public String download_url;
    }

    /**
     * Output class that contains either the retrieved content or error information.
     * Handles both single file and directory listing scenarios.
     */
    public class GetContentOutput {
        @InvocableVariable(description='Content information for the requested path')
        public ContentInfo content;

        @InvocableVariable(description='List of contents if the path is a directory')
        public List<ContentInfo> directory_contents;

        @InvocableVariable(description='Error message if the request failed')
        public String error_message;

        public GetContentOutput() {
            directory_contents = new List<ContentInfo>();
        }
    }

    /**
     * Main invocable method that retrieves content from a GitHub repository.
     * This method can handle both single files and directory listings.
     */
    @InvocableMethod(label='Get GitHub Repository Content'
                     description='Retrieves content (file or directory listing) from a GitHub repository')
    public static List<GetContentOutput> getContent(List<GetContentInput> inputs) {
        List<GetContentOutput> outputs = new List<GetContentOutput>();

        for(GetContentInput input : inputs) {
            GetContentOutput output = new GetContentOutput();

            try {
                // Input validation to ensure we have the required data
                if (String.isBlank(input.path)) {
                    throw new IllegalArgumentException('Path cannot be empty');
                }

                Http http = new Http();
                HttpRequest request = new HttpRequest();

                // Construct the endpoint URL with proper encoding of path components
                String endpoint = 'callout:GitHub_API/repos/' +
                    EncodingUtil.urlEncode(input.owner, 'UTF-8') + '/' +
                    EncodingUtil.urlEncode(input.repo, 'UTF-8') + '/contents/' +
                    EncodingUtil.urlEncode(input.path, 'UTF-8');

                // Add ref parameter if specified
                if (String.isNotBlank(input.ref)) {
                    endpoint += '?ref=' + EncodingUtil.urlEncode(input.ref, 'UTF-8');
                }

                request.setEndpoint(endpoint);
                request.setMethod('GET');
                request.setTimeout(20000); // 20 second timeout

                HttpResponse response = http.send(request);

                if (response.getStatusCode() == 200) {
                    Object responseData = JSON.deserializeUntyped(response.getBody());

                    // Handle both single file and directory responses
                    if (responseData instanceof List<Object>) {
                        // Directory listing
                        List<Object> contents = (List<Object>)responseData;
                        for (Object item : contents) {
                            Map<String, Object> contentMap = (Map<String, Object>)item;
                            ContentInfo content = parseContentInfo(contentMap);
                            if (content != null) {
                                output.directory_contents.add(content);
                            }
                        }
                    } else {
                        // Single file
                        Map<String, Object> contentMap = (Map<String, Object>)responseData;
                        output.content = parseContentInfo(contentMap);
                    }
                } else {
                    // Handle error response from GitHub
                    Map<String, Object> errorResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                    String message = (String)errorResponse.get('message');
                    output.error_message = 'GitHub API Error: ' + message + ' (Status: ' + response.getStatusCode() + ')';
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
     * Helper method to parse GitHub content information into our ContentInfo structure.
     * Handles various data types and potential null values safely.
     */
    private static ContentInfo parseContentInfo(Map<String, Object> contentMap) {
        if (contentMap == null) return null;

        ContentInfo content = new ContentInfo();

        try {
            content.type = (String)contentMap.get('type');

            // Handle size value which can come in different numeric types
            Object sizeObj = contentMap.get('size');
            if (sizeObj != null) {
                if (sizeObj instanceof Integer) {
                    content.size = (Long)((Integer)sizeObj);
                } else if (sizeObj instanceof Long) {
                    content.size = (Long)sizeObj;
                } else if (sizeObj instanceof Decimal) {
                    content.size = ((Decimal)sizeObj).longValue();
                }
            }

            content.name = (String)contentMap.get('name');
            content.path = (String)contentMap.get('path');
            content.sha = (String)contentMap.get('sha');
            content.html_url = (String)contentMap.get('html_url');
            content.download_url = (String)contentMap.get('download_url');

            // Handle content decoding for files
            String rawContent = (String)contentMap.get('content');
            if (String.isNotBlank(rawContent)) {
                // Remove line breaks that GitHub adds to the base64 content
                rawContent = rawContent.replace('\n', '');
                try {
                    // Attempt to decode the base64 content
                    content.content = EncodingUtil.base64Decode(rawContent).toString();
                } catch (Exception e) {
                    // If decoding fails, store the raw content
                    content.content = rawContent;
                    System.debug('Warning: Could not decode content for ' + content.path);
                }
            }

        } catch (Exception e) {
            System.debug('Error parsing content info: ' + e.getMessage());
            return null;
        }

        return content;
    }
}
