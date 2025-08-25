// Import the function that handles communication with the OpenAI API.
// This abstraction isolates service-level concerns (authentication, persona handling, model selection)
// from the orchestration logic in this module, improving modularity and testability.
import { getSasAssistantResponse } from '../services/openaiClient.js';

// Import the utility responsible for formatting and styling assistant responses for CLI display.
// This keeps rendering logic separate from core assistant behavior, maintaining a clear separation of concerns.
import { formatResponse } from '../utils/formatter.js';

// Import the logging function to record input/output interactions to disk.
// Centralized logging is configured via environment settings and supports multiple output modes.
// This is useful for auditing, debugging, and session replay in future features.
import { logInteraction } from '../utils/logger.js';

/**
 * Handles a user's input prompt and manages the assistant interaction lifecycle:
 * 1. Sends the prompt to the AI assistant using the specified persona
 * 2. Receives and processes the assistant’s response
 * 3. Delegates the response to a formatter for styled output
 *
 * @param {string} promptText - The user's question or command input.
 * @param {string} [persona] - Optional assistant persona (e.g., 'sas', 'sql', 'mentor').
 */
export async function handlePrompt(promptText, persona) {
  // Step 1: Retrieve a response from the AI assistant based on prompt and persona.
  const response = await getSasAssistantResponse(promptText, persona);

  // Step 2: Format and display the assistant's response for the terminal.
  formatResponse(response, persona);

  // console.log('[DEBUG] Logging interaction...');
  // Log the input and output for the session
  logInteraction({ input: promptText, response, persona });
}

/**
 * Why This Design Works:
 *
 * - Separation of Concerns:
 *   This module focuses purely on workflow orchestration — not how prompts are sent
 *   or how responses are rendered. Each responsibility lives in its own layer.
 *
 * - Scalability:
 *   You can add retry logic, logging, analytics, or context management here
 *   without touching the API or UI layers.
 *
 * - Testability:
 *   Since both `getSasAssistantResponse` and `formatResponse` are imported dependencies,
 *   they can be easily mocked for isolated unit testing.
 *
 * - Extensibility:
 *   It's simple to extend this logic to support things like output logging,
 *   persona switching, or even post-processing of responses.
 *
 * - SOLID Compliant:
 *   Adheres to the Single Responsibility Principle — this function acts as the controller
 *   for the assistant's input/output lifecycle without taking on unrelated concerns.
 */
