# Agentforce Engineering Agent

This agent provides programming assistance and integrates with development tools like Asana and GitHub to help engineering teams be more productive directly from Salesforce and Slack.

> [!TIP]
> Check out the [instructions](./INSTRUCTIONS.md) to get started building your own engineering agent!

## What is an Agentforce agent?

An Agentforce agent is a specialized AI assistant that works within Salesforce, powered by Salesforce's Atlas Reasoning Engine. It helps users accomplish specific tasks by using Flows, Apex code, and natural language instructions to orchestrate actions on their behalf.

## What does this engineering agent do?

This agent serves as a technical assistant that can help with programming tasks and manage development tools. It combines general programming knowledge with direct integrations to Asana for task management and GitHub for code management.

### Answer general programming questions

The agent can provide guidance on programming concepts, help solve coding problems, and offer best practices across various programming languages and development scenarios. It draws on extensive programming knowledge to help developers understand and implement solutions.

### Task and project management with Asana

The agent integrates with Asana to help manage tasks and projects. It can:
- Search for tasks across workspaces
- Create and update tasks
- Manage task tags and organization
- Navigate workspace and project structures
- Handle sections and project organization

### Code management with GitHub

The agent provides GitHub integration to help manage code and development workflows. It can:
- Search repositories and code
- Manage pull requests
- Access repository content
- Create development environments through codespaces
- Handle repository-related tasks

## How does it work?

The agent uses `Apex invocable actions` and `natural language instructions` to understand user requests and take appropriate actions. It interfaces with external services through authenticated API calls and manages the responses to provide meaningful results to users.

### Topics and actions

Topics organize related actions into logical groups that help the agent understand what capabilities it has and when to use them. The engineering agent combines three custom topics with one standard topic that comes with all Agentforce agents:

Custom Topics (not included in Agentforce):
- General Programming Knowledge
- Asana Integration
- GitHub Integration

Standard Topics (included in Agentforce):
- General Slack Actions - Enables Slack integration features like creating canvases, starting DMs, looking up users, and searching Slack content

Each topic contains specific actions that the agent can take, like searching for tasks or creating pull requests. The agent uses natural language processing to understand which actions are appropriate for a given request.

### Customizing Agentforce with custom actions

Agentforce can be extended with custom actions written in Apex, using Flows, or using prompt templates. The actions in this example are Apex classes that use the `@InvocableMethod` annotation to make them available in Agentforce. Custom actions can integrate with any system accessible via API and can implement any business logic needed.

### Explaining Apex

Apex is Salesforce's proprietary programming language that runs on Salesforce Platform. It's a strongly-typed, object-oriented language that allows developers to execute flow and transaction control statements on the platform. Apex shares many similarities with Java in terms of syntax and structure, making it familiar to Java developers. For this agent, Apex provides the foundation for building custom actions that integrate with external services.

> [!TIP]
> Apex is very similar to Java in both syntax and behavior!

### Explaining Invocable Actions and Related Annotations

Invocable actions are Apex classes that can be executed from Flows or the Atlas Reasoning Engine. They use the `@InvocableMethod` annotation to expose their functionality and can accept complex input parameters and return complex output types. They support bulk operations and can be called synchronously or asynchronously.

Key annotations include:
- `@InvocableMethod`: Marks a method as callable from Flows
- `@InvocableVariable`: Defines input and output variables for the action
- `@TestVisible`: Makes private methods accessible for testing

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
        @InvocableVariable(required=true description='Important input value')
        public String inputValue;
    }

    public class ActionOutput {
        @InvocableVariable
        public String result;
    }

    @InvocableMethod(label='My Custom Action' description='Performs an important, discrete action')
    public static List<ActionOutput> execute(List<ActionInput> inputs) {
        // Implementation
    }
}
```
