# Instructions

## Setting up Your Development Environment

There are two methods of developing with Apex, using the Code Builder developer environment within Salesforce Platform or using VSCode with the proper Salesforce extensions installed. This guide focuses on using VSCode as your development environment.

* Install the Salesforce CLI
* Open VSCode and navigate to the extensions tab
  * Search for (and install) the `Salesforce Extension Pack`
  * Reload the window to activate the new extensions
* From the VSCode command palette (Cmd/Ctrl + Shift + P), search for `SFDX:Create Project and select it from the list of options`
  * For the template type, leave Standard selected and press Enter
  * Give your project a name like Custom Platform Actions and press Enter
  * Choose a destination on your computer for the project and click Create Project
  * From the VSCode command palette, search for SFDX: Authorize an Org and select it from the list of options
    * Leave Project Default selected for login URL source and press Enter
    * Set an org alias like customActionsOrg or leave the default and press Enter
    * On the Salesforce login page, enter your Username and Password and click Log In
    * Allow access for the Salesforce CLI to act on your behalf by clicking Allow
    * You will get a notification in VSCode if authentication was successful


## Setting up your GitHub and Asana actions

> [!NOTE]
> You'll need to repeat these steps for both platforms.

### Create your app

To use an external API in custom actions within Agentforce, you first need to set up proper credentials. This is done by creating an OAuth app in your chosen platform (in this case GitHub and Asana) and using an Auth. Provider in Salesforce to manage the authentication flow.

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

### Create Your Apex Classes

Create custom actions that use your Named Credential to interact with the external API. In this case you can use the included classes for [GitHub](./engineering-agent/github/classes) and [Asana](./engineering-agent/asana/classes), or create your own.

* Plan your actions:
  * Consider what discrete operations users might need
  * Break complex operations into composable steps
  * Define clear input and output parameters
* Create your action classes:
  * Use @InvocableMethod annotation
  * Include proper error handling
  * Use the Named Credential for API calls
* Test your actions locally

### Make Actions Available in Agent Builder

* Assign permissions for Einstein Agent User:
  * In Profiles, select `Einstein Agent User`
  * Under `Apex Class Access`, enable access to your new classes
* Create Agent Actions:
  * In setup, go to `Agent Actions`
  * Create new actions from your Apex classes
  * Configure appropriate labels and instructions

> [!NOTE]
> Be sure to select `Show in conversation` for any output parameters you want the agent to share with the user!

## Setting up the custom LLM action for code instruction

### Create a Fastify server for your LLM connector

* Create new directory and initialize project
  * `mkdir llm-connector && cd llm-connector`
  * `npm init -y`
  * Install dependencies: `npm install fastify @huggingface/inference dotenv`
* Create server file `server.js`:
  * Copy the [example server setup](./engineering-agent/general-programming-knowledge/example-fastify-server.js) into your file
  * Create `.env` file and add the following:

```bash
API_TOKEN=your-secure-token-here
HUGGINGFACE_API_KEY=your-hf-key-here
PORT=3000
```

### Set up model inference on HuggingFace.co

* Identify the model you want to use from the models directory
* Update the server code with the proper model name and settings

> [!IMPORTANT]
> Before setting up your connector, ensure you have access to a HuggingFace inference provider.
>
> Using HuggingFace's inference routing with the `hf-inference` provider:
>
> ```javascript
> const hf = new HfInference(process.env.HUGGINGFACE_API_KEY, {
>   provider: "hf-inference"
> });
> ```
>
> Using a specific provider like Together AI, Replicate, fal.ai, or SambaNova:
>
> ```javascript
> const hf = new HfInference(process.env.HUGGINGFACE_API_KEY, {
>   provider: "together" // or "replicate", "fal-ai", "sambanova"
> });
> ```

### Deploy your connector

* Create Heroku app
  * Add environment variables in Settings > Config Vars:
    * `API_TOKEN`
    * `HUGGINGFACE_API_KEY`
* Deploy
  * Connect GitHub repo or use Heroku CLI to deploy
  * Verify `/health` endpoint works
* Log
  * Run `heroku logs --tail` to see your app's logs for testing

### Test your connector

Use cURL to test the chat completions endpoint:

```bash
curl -X POST https://your-app-name.herokuapp.com/chat/completions \
-H 'Content-Type: application/json' \
-H 'api-key: your-api-token' \
-d '{
    "messages": [
        {
            "role": "user",
            "content": "Test message to verify the model works"
        }
    ]
}'
```

### Create Your Apex Class

Just like with GitHub and Asana, you'll need to create an [Apex class](./engineering-agent/general-programming-knowledge/classes/GeneralProgrammingKnowledgeAction.cls) for your custom LLM action.

* Create your action class
  * Use @InvocableMethod annotation
  * Include proper error handling
* Test your action locally

### Make Action Available in Agent Builder

* Assign permissions for Einstein Agent User:
  * In Profiles, select `Einstein Agent User`
  * Under `Apex Class Access`, enable access to your new class
* Create Agent Action:
  * In setup, go to `Agent Actions`
  * Create new actions from your Apex classes
  * Configure appropriate labels and instructions

## Create the Engineering Agent

Now that you have all your actions set up, it's time to build the actual agent and configure it!

### Building your agent

* From the Agents setup, click New
  * For the agent settings, enter the information in the [README](./engineering-agent/README.md) for the agent.
  * Open your agent in Builder
  * For each custom topic:
    * Create a new topic for your agent
    * Add the settings in the related README file
  * For the standard Slack Actions:
    * Create a new topic from the Asset Library
    * Select the `General Slack Actions` topic
    * Save

### Testing your agent

* Click `Activate` for your agent within Agent Builder
* Copy sample prompts from the topic READMEs and confirm your agent is working
