# Asana Topic & Actions

The Asana topic provides a comprehensive set of actions for managing tasks, projects, and workspaces in Asana directly through the Agentforce agent. This topic enables agents to perform the full range of task management operations, from creating and updating tasks to organizing them with tags and sections, while maintaining proper workspace and project boundaries.

**Topic Label**: Asana Actions

**Classification Description**: Allows agents to manage Asana tasks and workspaces on behalf of users, performing actions like creating and updating tasks, managing tags, organizing projects and sections, and searching workspace content.

**Scope**: You can assist with the full lifecycle of Asana tasks: creating new tasks, updating existing ones, retrieving task details, managing tags, organizing tasks in sections, and deleting tasks when needed. This includes handling task properties, various searches, and task tag associations. All operations respect project and workspace boundaries.

## Instructions

* Whenever the user asks you for tasks that are in the backlog use the Get Asana Tasks By Project Section action to get them by looking up the section named "Backlog".
* Always confirm before deleting a task.
* Whenever the user asks you for tasks that are in progress use the Get Asana Tasks By Project Section action to get them by looking up the section named "In Progress".
* Always search for similar tasks and verify with the user before creating a new one.
* Always use the Update Asana Task action when the user asks you to mark a task as complete.
* When the user asks you to get all tasks by a tag name, use the Get Asana Tags by Workspace action.
* If you need to know which workspace to take an action in, use the Get Asana Workspaces action to list the workspaces and ask the user which one to use.

## Available Actions

### Task Management
* [SearchAsanaTasksByWorkspaceAction](./classes/SearchAsanaTasksByWorkspaceAction.cls) - Search for tasks in a workspace with optional filters
* [GetAsanaTaskAction](./classes/GetAsanaTaskAction.cls) - Get detailed information about a specific task
* [CreateAsanaTaskAction](./classes/CreateAsanaTaskAction.cls) - Create a new task with specified properties
* [UpdateAsanaTaskAction](./classes/UpdateAsanaTaskAction.cls) - Update an existing task's properties
* [DeleteAsanaTaskAction](./classes/DeleteAsanaTaskAction.cls) - Delete a task from Asana

### Tag Operations
* [AddTagToAsanaTaskAction](./classes/AddTagToAsanaTaskAction.cls) - Add a tag to an existing task
* [RemoveTagFromAsanaTaskAction](./classes/RemoveTagFromAsanaTaskAction.cls) - Remove a tag from a task
* [GetAsanaTasksByTagAction](./classes/GetAsanaTasksByTagAction.cls) - Find all tasks with a specific tag
* [GetAsanaTagsByWorkspaceAction](./classes/GetAsanaTagsByWorkspaceAction.cls) - List all tags in a workspace

### Workspace and Project Management
* [GetAsanaWorkspacesAction](./classes/GetAsanaWorkspacesAction.cls) - List all accessible workspaces
* [GetAsanaProjectsByWorkspaceAction](./classes/GetAsanaProjectsByWorkspaceAction.cls) - Get all projects in a workspace
* [GetAsanaSectionsByProjectAction](./classes/GetAsanaSectionsByProjectAction.cls) - List sections within a project
* [GetAsanaTasksByProjectSectionAction](./classes/GetAsanaTasksByProjectSectionAction.cls) - Get tasks in a specific project section

## Example Prompts

* "Show me all tasks tagged with 'urgent'"
* "What tasks are currently in progress?"
* "Get me all the tasks in the backlog"
* "Mark task 'Update documentation' as complete"
* "Create a new task for updating the API documentation"
* "Move task 'Refactor authentication' to In Progress"
* "Find all tasks related to the frontend project"
* "Add the 'bug' tag to task 'Fix login issue'"
* "What tasks are assigned to me that are due this week?"
* "Remove the 'blocked' tag from the 'Database migration' task"
