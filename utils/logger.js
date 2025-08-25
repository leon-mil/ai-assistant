import fs from 'fs';
import path from 'path';
import { config } from '../config/env.js';

/**
 * Why This Design Works:
 * 
 * - Explicit file path resolution and directory creation
 * - Defends against path errors and mode misconfiguration
 * - Outputs user-friendly logs, while being modular and extendable
 */

let logPath = '';
let initialized = false;

/**
 * Initializes the log system based on user config.
 * Creates the output directory and determines the full log path.
 */
function initLogFile() {
  if (!config.logging.enabled || initialized) return;

  const logDir = path.resolve(config.logging.directory);
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

  switch (config.logging.mode) {
    case 'rotate':
      logPath = path.join(logDir, `session_${timestamp}.log`);
      break;
    case 'overwrite':
      logPath = path.join(logDir, config.logging.filename);
      fs.writeFileSync(logPath, ''); // Reset the file
      break;
    case 'append':
    default:
      logPath = path.join(logDir, config.logging.filename);
      break;
  }

  initialized = true;
}

/**
 * Logs a single assistant interaction with structured formatting.
 * 
 * @param {Object} param
 * @param {string} param.input - User input
 * @param {string} param.response - Assistant response
 * @param {string} param.persona - Active persona at the time
 */
export function logInteraction({ input, response, persona }) {
  if (!config.logging.enabled) return;

  if (!initialized) initLogFile();

  const entry = `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧑   Persona: ${persona}
⏰      Time: ${new Date().toLocaleString()}
🔹      User: ${input.trim()}
🔸 Assistant: ${response.trim()}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`;

  try {
    fs.appendFileSync(logPath, entry, { encoding: 'utf-8' });
  } catch (err) {
    console.error('[Logger Error]', err.message);
  }
}
