import * as dotenv from 'dotenv';

// Load environment variables from .env file into process.env.
// Ensures secrets and configuration are kept out of the source code.
dotenv.config();

/**
 * Why This Design Works:
 *
 * - Separation of Concerns:
 *   Configuration logic is cleanly separated from application logic. No business logic
 *   is dependent on how values are sourced or stored.
 *
 * - Testability:
 *   The config object can be easily mocked or injected for testing purposes without needing
 *   to modify the environment.
 *
 * - Flexibility:
 *   Developers can change models, temperature, or assistant behavior dynamically
 *   via `.env` values without touching any code.
 *
 * - Security:
 *   Sensitive data like API keys never appear in the source. They are managed through
 *   environment variables and excluded from version control.
 *
 * - Maintainability:
 *   All config values are centralized, reducing duplication, making updates simple,
 *   and ensuring consistency across the codebase.
 */

// Export a central configuration object with default fallbacks.
// All environment variables used throughout the app should come from here.
export const config = {
  // OpenAI API key for authenticating requests
  apiKey: process.env.OPENAI_API_KEY,

  // OpenAI model to use (e.g., 'gpt-4' or 'gpt-3.5-turbo')
  model: process.env.OPENAI_MODEL || 'gpt-5-mini', // Default to GPT-5 if not specified

  // Enables mock mode for testing without real API calls
  mock: process.env.OPENAI_MOCK === 'true',

  // Temperature controls output randomness (0.0 = deterministic, 1.0 = creative)
  temperature: parseFloat(process.env.OPENAI_TEMPERATURE) || 0.4,

  // Defines the assistant's behavior/persona via system prompt
  // Define multiple assistant personas by name
  personas: {
    sas: 'You are a helpful SAS programming assistant. Respond with clean, well-formatted explanations and SAS code.',
    sql: 'You are a knowledgeable SQL assistant. Answer queries with explanations and well-formatted SQL code.',
    mentor: 'You are a thoughtful mentor. Provide practical career and technical advice with empathy and clarity.',
    debugger: 'You are a code reviewer. Explain and help fix bugs in SAS code step by step.',
    teacher: 'You are a SAS teacher. Explain concepts slowly with analogies and beginner-friendly examples.'
  },

  // Choose default persona (fallback if not overridden by user or prompt)
  defaultPersona: process.env.OPENAI_PERSONA || 'sas',

  logging: {
    // Enables or disables logging system-wide.
    // Accepts "false" (as a string) to disable. Defaults to true if unset.
    enabled: process.env.LOGGING_ENABLED !== 'false',
  
    // Defines how log files are handled:
    // - 'rotate': Creates a new timestamped file on every run
    // - 'append': Appends all logs to a single persistent file
    // - 'overwrite': Clears and rewrites the same log file each run
    mode: process.env.LOGGING_MODE || 'rotate',
  
    // Specifies the output directory for log files.
    // Can be a relative or absolute path (e.g., './logs', '/var/log/sas')
    directory: process.env.LOGGING_DIR || 'logs',
  
    // Name of the log file when mode is 'append' or 'overwrite'.
    // Ignored when mode is 'rotate' (since that mode auto-generates filenames)
    filename: process.env.LOGGING_FILENAME || 'session.log',

    // retentionDays determines how long log files should be retained before being deleted.
    // It is read from the LOG_RETENTION_DAYS environment variable (in `.env`).
    // 
    // - The value is parsed as a base-10 integer using parseInt(..., 10) for clarity and reliability.
    // - If the variable is not defined or invalid, it falls back to a default of 7 days.
    //
    // This value is used by the log cleanup script (e.g., `clean-logs.ps1`) to decide
    // which log files are old enough to be deleted based on their LastWriteTime.
    //
    // Note: If your system also supports LOG_RETENTION_MINUTES, that value should take precedence
    // in runtime logic. This value should only be used if LOG_RETENTION_MINUTES is not set.
    retentionDays: parseInt(process.env.LOG_RETENTION_DAYS, 10) || 7,
  },
  
  // Commands that the user can enter to gracefully exit the assistant
  // Centralizing these supports better UX and future customization (e.g., ":q", "bye", etc.)
  exitCommands: (process.env.OPENAI_EXIT_COMMANDS || 'exit,quit,q,:q').split(','),
};
