/**
 * Class for merging GitHub Pull Requests
 */
public class MergeGitHubPRAction {

    /**
     * Input class for the Agentforce PR merge action
     * Provides structured inputs for PR merging
     */
    public class MergePRInput {
        @InvocableVariable(required=true description='Repository containing the PR (format: owner/repo)')
        public String repository;

        @InvocableVariable(required=true description='The number that identifies the PR')
        public Integer pull_number;

        @InvocableVariable(description='Merge method to use (merge, squash, rebase)')
        public String merge_method;

        @InvocableVariable(description='Title for the merge commit')
        public String merge_commit_title;

        @InvocableVariable(description='Message for the merge commit')
        public String merge_commit_message;
    }

    /**
     * Class representing a PR merge result
     */
    public class MergeResult {
        @InvocableVariable(description='Whether the PR was successfully merged')
        public Boolean merged;

        @InvocableVariable(description='Pull request number')
        public Integer pull_number;

        @InvocableVariable(description='URL of the PR')
        public String url;

        @InvocableVariable(description='SHA of the merge commit')
        public String merge_commit_sha;

        @InvocableVariable(description='Message from the merge operation')
        public String message;

        @InvocableVariable(description='Error message if merge failed')
        public String error_message;
    }

    /**
     * Main invocable method for merging a GitHub pull request
     */
    @InvocableMethod(label='Merge GitHub Pull Request' description='Merges a GitHub pull request')
    public static List<MergeResult> mergePullRequest(List<MergePRInput> inputs) {
        List<MergeResult> results = new List<MergeResult>();

        for(MergePRInput input : inputs) {
            MergeResult result = new MergeResult();
            result.pull_number = input.pull_number;

            try {
                // Validate repository format
                if (!input.repository.contains('/')) {
                    throw new IllegalArgumentException('Repository must be in format owner/repo');
                }

                Http http = new Http();
                HttpRequest mergeRequest = new HttpRequest();

                // Build the endpoint URL for merging the PR
                String endpoint = 'callout:GitHub_API/repos/' + input.repository +
                    '/pulls/' + input.pull_number + '/merge';

                mergeRequest.setEndpoint(endpoint);
                mergeRequest.setMethod('PUT');
                mergeRequest.setHeader('Accept', 'application/vnd.github+json');

                // Build merge payload
                Map<String, Object> mergeBody = new Map<String, Object>();

                if (String.isNotBlank(input.merge_method)) {
                    mergeBody.put('merge_method', input.merge_method.toLowerCase());
                }
                if (String.isNotBlank(input.merge_commit_title)) {
                    mergeBody.put('commit_title', input.merge_commit_title);
                }
                if (String.isNotBlank(input.merge_commit_message)) {
                    mergeBody.put('commit_message', input.merge_commit_message);
                }

                mergeRequest.setBody(JSON.serialize(mergeBody));

                HttpResponse mergeResponse = http.send(mergeRequest);

                if (mergeResponse.getStatusCode() == 200) {
                    Map<String, Object> mergeData = (Map<String, Object>)JSON.deserializeUntyped(mergeResponse.getBody());

                    result.merged = true;
                    result.merge_commit_sha = (String)mergeData.get('sha');
                    result.message = (String)mergeData.get('message');
                } else {
                    result.merged = false;
                    result.error_message = 'Merge failed with status code: ' +
                        mergeResponse.getStatusCode() + '. Response: ' + mergeResponse.getBody();
                }

            } catch(Exception e) {
                result.merged = false;
                result.error_message = 'Error: ' + e.getMessage();
                System.debug('Error details: ' + e.getStackTraceString());
            }

            results.add(result);
        }

        return results;
    }
}
