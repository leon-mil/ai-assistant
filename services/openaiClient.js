// Import the official OpenAI SDK for Node.js v4+.
// This SDK provides access to the ChatGPT (GPT-4, GPT-3.5, etc.) API endpoints
// in a clean and promise-based interface.
import OpenAI from 'openai';

// Import environment-based configuration (API key, model, temperature, personas).
// This ensures we don’t hardcode secrets or model choices here,
// and keeps our service layer loosely coupled and easily configurable.
import { config } from '../config/env.js';

// Create and configure an OpenAI client instance.
// This object is used to send requests to the OpenAI API.
// The API key is injected via the centralized config file.
const openai = new OpenAI({ apiKey: config.apiKey });

/**
 * Generates a response from the assistant powered by OpenAI.
 * This function sends the user prompt along with the selected persona's
 * system message to the GPT model, and returns the assistant's reply.
 *
 * @param {string} promptText - The input message from the user.
 * @param {string} [persona=config.defaultPersona] - Optional persona override.
 * @returns {Promise<string>} - The assistant's response text.
 */
export async function getSasAssistantResponse(promptText, persona = config.defaultPersona) {
  // Use the selected persona's system prompt, or fallback to default.
  const systemMessage = config.personas[persona] || config.personas[config.defaultPersona];

  const response = await openai.chat.completions.create({
    model: config.model,
    messages: [
      { role: 'system', content: systemMessage },
      { role: 'user', content: promptText },
    ],
    temperature: config.temperature,
  });

  // Return only the assistant’s reply message content.
  return response.choices[0].message.content;
}

/**
 * Why This Design Works:
 *
 * - Single Responsibility:
 *   This file is solely responsible for interfacing with OpenAI.
 *
 * - Encapsulation:
 *   All external dependencies (API key, model, personas) are pulled from config,
 *   keeping the service layer isolated and reusable.
 *
 * - Open for Extension:
 *   You can add support for other OpenAI features (image generation, tools, streaming)
 *   without modifying the core assistant logic.
 *
 * - Reusable:
 *   This function can be used by CLI tools, GUIs, web APIs, or tests without modification.
 *
 * - SOLID Compliant:
 *   Follows Dependency Inversion by relying on configuration abstractions
 *   and clear message construction rules.
 */
