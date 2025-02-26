# GitHub Topic & Actions

The GitHub topic enables agents to interact with GitHub repositories, manage pull requests, search code, and handle development environments through codespaces. This topic provides comprehensive access to GitHub's functionality while maintaining proper security and access controls.

**Topic Label**: GitHub Actions

**Classification Description**: Allows agents to interact with GitHub repositories on behalf of users, performing actions like searching code and content, managing pull requests, creating codespaces, and accessing repository information.

**Scope**: Your job is to help people manage their GitHub workflows by searching repositories and code, accessing repository content, creating and managing pull requests, setting up development environments through codespaces, and handling repository-related tasks.

## Instructions

* Always confirm before any destructive operations that would modify or delete repository content, repositories, issues, or PRs
* Never ask for IDs or PR numbers, use the related actions to look them up

## Available Actions

### Repository Management
* [GetGitHubRepositoriesAction](./classes/GetGitHubRepositoriesAction.cls) - List and access available repositories
* [GetGitHubRepositoryAction](./classes/GetGitHubRepositoryAction.cls) - Get detailed information about a specific repository
* [GetGitHubRepositoryContentAction](./classes/GetGitHubRepositoryContentAction.cls) - Access and retrieve repository content

### Pull Request Operations
* [GetGitHubRepositoryPRsAction](./classes/GetGitHubRepositoryPRsAction.cls) - List pull requests in a repository
* [UpdateGitHubPRAction](./classes/UpdateGitHubPRAction.cls) - Modify existing pull requests
* [MergeGitHubPRAction](./classes/MergeGitHubPRAction.cls) - Merge pull requests into their target branches
* [CreateGitHubCodespaceFromPRAction](./classes/CreateGitHubCodespaceFromPRAction.cls) - Create development environments from pull requests

### Search
* [SearchGitHubCodeAction](./classes/SearchGitHubCodeAction.cls) - Search for code across repositories
* [SearchGitHubPRsAction](./classes/SearchGitHubPRsAction.cls) - Find pull requests matching specific criteria

## Example Prompts

* "Do I have any open PRs in the myorg/myrepo repository?"
* "Show me all pull requests with the 'dependencies' label"
* "Create a codespace for PR #123"
* "Can you merge the PR for the feature/auth-update branch?"
* "Search the codebase for all instances of 'deprecated-function'"
* "Find all PRs that modify the authentication service"
* "Show me the contents of the README in the main branch"
* "List all repositories in the organization"
* "Get the status of the latest PR in the frontend repository"
* "Search for PRs containing security updates"
