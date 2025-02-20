# Agentforce Engineering Agent

This agent provides programming assistance and integrates with development tools like Asana and GitHub to help engineering teams be more productive directly from Salesforce and Slack.

## What is an Agentforce agent?

An Agentforce agent is a specialized AI assistant that works within Salesforce, powered by Salesforce's Atlas Reasoning Engine. It helps users accomplish specific tasks by using Flows, Apex code, and natural language instructions to orchestrate actions on their behalf.

## What does this engineering agent do?

This agent serves as a technical assistant that can help with programming tasks and manage development tools. It combines general programming knowledge with direct integrations to Asana for task management and GitHub for code management.

### Answer general programming questions

The agent can provide guidance on programming concepts, help solve coding problems, and offer best practices across various programming languages and development scenarios. It draws on extensive programming knowledge to help developers understand and implement solutions.

### Help with Asana

The agent integrates with Asana to help manage tasks and projects. It can:
- Search for tasks across workspaces
- Create and update tasks
- Manage task tags and organization
- Navigate workspace and project structures
- Handle sections and project organization

### Help with GitHub

The agent provides GitHub integration to help manage code and development workflows. It can:
- Search repositories and code
- Manage pull requests
- Access repository content
- Create development environments through codespaces
- Handle repository-related tasks

## How does it work?

The agent uses Apex invocable actions and natural language processing to understand user requests and take appropriate actions. It interfaces with external services through authenticated API calls and manages the responses to provide meaningful results to users.

### Topics and actions

Topics organize related actions into logical groups that help the agent understand what capabilities it has and when to use them. The engineering agent combines three custom topics with one standard topic that comes with all Agentforce agents:

Custom Topics:
- General Programming Knowledge
- Asana Integration
- GitHub Integration

Standard Topic:
- General Slack Actions - Enables Slack integration features like creating canvases, starting DMs, looking up users, and searching Slack content

Each topic contains specific actions that the agent can take, like searching for tasks or creating pull requests. The agent uses natural language processing to understand which actions are appropriate for a given request.

### Customizing Agentforce with custom actions

Agentforce can be extended with custom actions written in Apex. These actions are standard Apex classes that use the @InvocableMethod annotation to make them available to Flows and the Atlas Reasoning Engine. Custom actions can integrate with any system accessible via API and can implement any business logic needed.

### Explaining Apex

Apex is Salesforce's proprietary programming language that runs in the Lightning Platform. It's a strongly-typed, object-oriented language that allows developers to execute flow and transaction control statements on the platform. Apex shares many similarities with Java in terms of syntax and structure, making it familiar to Java developers. For this agent, Apex provides the foundation for building custom actions that integrate with external services.

### Explaining Invocable Actions and Related Annotations

Invocable actions are Apex methods that can be executed from Flows or the Atlas Reasoning Engine. They use the @InvocableMethod annotation to expose their functionality and can accept complex input parameters and return complex output types. They support bulk operations and can be called synchronously or asynchronously.

Key annotations include:
- @InvocableMethod: Marks a method as callable from Flows
- @InvocableVariable: Defines input and output variables for the action
- @TestVisible: Makes private methods accessible for testing

### Using Apex to write Invocable Actions

Invocable actions follow a specific pattern:
1. Define input and output classes with @InvocableVariable annotations
2. Create a class with an @InvocableMethod annotated method
3. Implement the business logic using Apex
4. Handle errors and return appropriate responses
5. Include proper test coverage

Example structure:
```apex
public class MyCustomAction {
    public class ActionInput {
        @InvocableVariable(required=true)
        public String inputValue;
    }

    public class ActionOutput {
        @InvocableVariable
        public String result;
    }

    @InvocableMethod(label='My Custom Action')
    public static List<ActionOutput> execute(List<ActionInput> inputs) {
        // Implementation
    }
}
```

---

## Getting Started

To use an external API in custom actions in Agentforce, you first need to set up proper credentials. This is done by creating an OAuth app in your chosen platform and using an Auth. Provider in Salesforce to manage the authentication flow.

* Navigate to your platform's developer portal or app settings
* Create a new app
  * Give it a name like "Agentforce Custom Actions"
  * Select the appropriate scope of installation (org/account-wide if available)
* Configure OAuth settings
  * Add necessary OAuth scopes based on your intended actions
  * Note your Client ID and Client Secret
* Save your app settings

### Create an Auth Provider

Create an auth provider to manage the authentication flow between your platform app and Salesforce.

* In Salesforce setup, search for "Auth. Providers" and click New:
  * For Provider Type select Open ID Connect
  * Name it after your platform
  * Leave URL Suffix as default
  * Enter your app's Client ID and Client Secret
  * Enter the platform's OAuth endpoints:
    * Authorize Endpoint URL
    * Token Endpoint URL
* Save the auth provider
* Copy the Callback URL
* Add the callback URL to your platform app's OAuth settings

### Create an External Credential

Set up an external credential to store your authentication tokens and connect them to a Principal.

* In Salesforce setup, under Named Credentials, select External Credentials tab and click New:
  * For Label name it after your platform
  * For Authentication Protocol: OAuth 2.0
  * For Authentication Flow Type: Browser Flow
  * Leave Scope blank
  * For Identity Provider: Select your auth provider
* Create a new Principal for your External Credential:
  * For Parameter Name: Your app name
  * For Sequence Number: 1
  * For Identity Type: Named Principal
  * Enter required OAuth scopes
* Save and authenticate the Principal
* Enable for Einstein Agent User and System Administrator profiles:
  * In Profiles, select Einstein Agent User
  * Under External Credentials Principal Access
  * Enable your credential
  * Repeat for System Administrator profile

### Create a Named Credential

Create a Named Credential to configure your API endpoint and headers.

* In Named Credentials, click New:
  * Label it "[Platform] API"
  * Name it similarly, but without spaces: Platform_API
  * For URL: Your platform's API base URL
  * Select your external credential
  * Save

### Set up Your Development Environment

Now that you have your named credential for your Platform wired up, you can use those actions to start creating the custom actions that will be used by agents within Agentforce. There are two methods of developing with Apex, using the Code Builder developer environment within Salesforce Platform or using VSCode with the proper Salesforce extensions installed. This guide focuses on using VSCode as your development environment.

* Install the Salesforce CLI
  * Navigate to this instruction page and install the CLI for your given environment
  * Confirm your installation by running sf --version in the terminal of your choice
* Setting up VSCode for Salesforce platform development
  * Open VSCode and navigate to the extensions tab
    * Search for (and install) the Salesforce Extension Pack
    * Reload the window to activate the new extensions
* Setting up a Salesforce development project
  * From the VSCode command palette (Cmd/Ctrl + Shift + P), search for SFDX:Create Project and select it from the list of options
  * For the template type, leave Standard selected and press Enter
  * Give your project a name like Custom Platform Actions and press Enter
  * Choose a destination on your computer for the project and click Create Project
  * From the VSCode command palette, search for SFDX: Authorize an Org and select it from the list of options
    * Leave Project Default selected for login URL source and press Enter
    * Set an org alias like customActionsOrg or leave the default and press Enter
    * On the Salesforce login page, enter your Username and Password and click Log In
    * Allow access for the Salesforce CLI to act on your behalf by clicking Allow
    * You will get a notification in VSCode if authentication was successful

### Create Custom Actions

Create custom actions that use your Named Credential to interact with the external API.

* Plan your actions:
  * Consider what discrete operations users might need
  * Break complex operations into composable steps
  * Define clear input and output parameters

* Create your action classes:
  * Use @InvocableMethod annotation
  * Include proper error handling
  * Use the Named Credential for API calls

* Test your actions thoroughly

### Make Actions Available in Agent Builder

* Assign permissions for Einstein Agent User:
  * In Profiles, select Einstein Agent User
  * Under Apex Class Access
  * Enable access to your new classes
* Create Agent Actions:
  * In setup, go to Agent Actions
  * Create new actions from your Apex classes
  * Configure appropriate labels and instructions
* Add to a Topic:
  * Open your agent in Builder
  * Create a new topic or select existing
  * Add your actions
  * Include clear instructions for action usage
* Test in Agent Builder
