// Import Node.js's built-in readline module to create a text-based interface.
// This allows the assistant to interact with the user through terminal I/O,
// handling text input and output line-by-line.
import readline from 'readline';

// Import chalk for styling and colorizing terminal output.
// This improves visual clarity and user experience by differentiating prompt, responses, and system messages.
import chalk from 'chalk';

// Import the core prompt handler which manages the assistant lifecycle.
// This abstraction keeps terminal logic decoupled from the AI/business logic.
import { handlePrompt } from '../core/assistant.js';

// Import runtime configuration, including user-defined exit commands.
// Centralized config allows easy customization without modifying this file.
import { config } from '../config/env.js';

/**
 * Initializes and runs the command-line interface (CLI) for the SAS assistant.
 * Displays a prompt, accepts user input, processes it through the assistant,
 * and renders the result in a styled, terminal-friendly format.
 *
 * =========================
 * USAGE INSTRUCTIONS
 * =========================
 *
 * 🔹 Ask a Question:
 *   Type your SAS-related question and press [Enter].
 *   Example: How do I merge two datasets in SAS?
 *
 * 🔹 Switch Assistant Persona:
 *   Use the command `/persona <name>` to change the assistant's behavior.
 *   Supported personas:
 *     - sas      → SAS programming expert (default)
 *     - sql      → SQL expert
 *     - mentor   → Technical and career guidance
 *     - debugger → SAS code reviewer
 *     - teacher  → Beginner-friendly explanations
 *   Example: /persona mentor
 *
 * 🔹 Exit the Assistant:
 *   Type one of the exit commands defined in `.env` (e.g., `exit`, `quit`, `:q`).
 *   These are customizable via the `OPENAI_EXIT_COMMANDS` variable.
 *
 * 🔹 Special Notes:
 *   - Current persona is shown in the prompt: 💬 [sas] Ask about SAS:
 *   - Responses include formatted code blocks where applicable
 *   - Logs are automatically saved if logging is enabled in `.env`
 */

/**
 * Initializes and runs the command-line interface (CLI) for the SAS assistant.
 * Displays a prompt, accepts user input, processes it through the assistant,
 * and renders the result in a styled, terminal-friendly format.
 */
export function startTerminal() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  let activePersona = config.defaultPersona;

  // Optional custom welcome messages per persona
  const personaWelcomeMessages = {
    sas: '💡 SAS mode activated. Ask about PROC steps, data steps, or macro logic.',
    sql: '💡 SQL mode activated. Ask me about queries, joins, optimization, or DDL.',
    mentor: '💡 Mentor mode on. Let’s talk career paths, goals, and strategies.',
    debugger: '💡 Debugger mode: I’ll help diagnose issues in your SAS code.',
    teacher: '💡 Teacher mode: I’ll explain concepts clearly with beginner-friendly examples.'
  };

  const setPrompt = () => rl.setPrompt(chalk.magenta(`💬 [${activePersona}] How can I help: `));

  setPrompt();
  rl.prompt();

  rl.on('line', async (input) => {
    const command = input.trim();
    const lower = command.toLowerCase();

    if (command === '') {
      console.log(chalk.yellowBright('\n⚠️  Please enter a question, command, or prompt. Press `/persona <name>` to switch personas or type something to begin.\n'));
      rl.prompt();
      return;
    }

    if (!/[a-zA-Z0-9]/.test(command)) {
      console.log(chalk.yellowBright('\n⚠️  That doesn’t look like a valid question. Try asking something about SAS, SQL, or switch persona using `/persona <name>`.\n'));
      rl.prompt();
      return;
    }

    // 1. Handle shorthand persona switching, e.g., /sas, /sql
    if (command.startsWith('/') && config.personas[command.slice(1)]) {
      const selected = command.slice(1);
      activePersona = selected;
      console.log(chalk.cyan(`\n✨ Persona switched to "${selected}"\n`));
      if (personaWelcomeMessages[selected]) {
        console.log(chalk.gray(personaWelcomeMessages[selected] + '\n'));
      }
      setPrompt();
      rl.prompt();
      return;
    }

    // 2. Handle full command: /persona sql
    if (lower.startsWith('/persona ')) {
      const selected = lower.split(' ')[1];
      if (config.personas[selected]) {
        activePersona = selected;
        console.log(chalk.cyan(`\n✨ Persona switched to "${selected}"\n`));
        if (personaWelcomeMessages[selected]) {
          console.log(chalk.gray(personaWelcomeMessages[selected] + '\n'));
        }
        setPrompt();
      } else {
        console.log(chalk.red(`\n❌ Unknown persona: "${selected}"\n`));
      }
      rl.prompt();
      return;
    }

    // Support listing all available personas with `/personas`
    if (command === '/personas') {
      console.log(chalk.cyan('\n📚 Available Personas:\n'));

      for (const [key, description] of Object.entries(config.personas)) {
        console.log(`• ${chalk.green(key.padEnd(10))} – ${description}`);
      }

      console.log(); // Extra spacing
      rl.prompt();
      return;
    }

    // Exit support
    if (config.exitCommands.includes(lower)) {
      console.log(chalk.yellowBright('\n👋 Exiting SAS Assistant. See you next time!\n'));
      rl.close();
      return;
    }

    await handlePrompt(input, activePersona);
    rl.prompt();
  });

  rl.on('SIGINT', () => {
    console.log(chalk.yellowBright('\n\n👋 Session ended. SAS Assistant signing off.\n'));
    rl.close();
  });
}
