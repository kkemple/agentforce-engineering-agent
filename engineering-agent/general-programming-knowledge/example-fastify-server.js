import "dotenv/config";
import Fastify from "fastify";
import { HfInference } from "@huggingface/inference";

const DEFAULT_SYSTEM_CONTENT = `Any default instructions for your model go here.`;

const server = Fastify({
  logger: true,
});

// Auth middleware
server.addHook("onRequest", async (request, reply) => {
  const apiKey = request.headers["api-key"];

  if (!apiKey || apiKey !== process.env.API_TOKEN) {
    reply.code(403).send({ error: "Invalid API token" });
    return;
  }
});

// Initialize HuggingFace client
server.decorate("hf", new HfInference(process.env.HUGGINGFACE_API_KEY));

// Chat completion endpoint
server.post("/chat/completions", {
  schema: {
    body: {
      type: "object",
      required: ["messages"],
      properties: {
        messages: {
          type: "array",
          items: {
            type: "object",
            required: ["role", "content"],
            properties: {
              role: { type: "string" },
              content: { type: "string" },
            },
          },
        },
      },
    },
  },
  handler: async (request) => {
    const systemMessages = [];
    const userMessages = [];

    if (request.body.messages.length === 1) {
      systemMessages.push({ role: "system", content: DEFAULT_SYSTEM_CONTENT });
    }

    for (const message of request.body.messages) {
      if ((message.role = "system")) {
        systemMessages.push(message);
      } else {
        userMessages.push(message);
      }
    }

    return server.hf.chatCompletion({
      model: "your-model-choice-here",
      messages: [...systemMessages, ...userMessages],
      provider: "hf-inference",
      max_tokens: 500,
    });
  },
});

// Health check endpoint
server.get("/health", async () => {
  return { status: "ok" };
});

// Start server
const start = async () => {
  try {
    server.listen({
      port: process.env.PORT || 3000,
      host: "0.0.0.0",
    });
    console.log(`Server listening on port ${process.env.PORT || 3000}`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
};

start();
