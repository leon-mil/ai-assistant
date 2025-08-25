// Import chalk to apply color and style formatting to terminal output.
// This improves readability and separates different content types visually.
import chalk from 'chalk';

/**
 * Formats the assistant's response for terminal display.
 * Distinguishes between plain text (explanation) and code blocks,
 * applying syntax-aware coloring using `chalk`.
 *
 * @param {string} content - The full raw response from the assistant.
 */
export function formatResponse(content, persona) {
  // Split the response into parts using code block markers (```sas or ```).
  // Odd-indexed segments will be code, even-indexed will be narrative/explanation.
  const parts = content.split(/```(?:sas)?/);

  // Display a clear heading before showing the response content.
  const personaLabel = persona?.toUpperCase() || 'ASSISTANT';
  console.log(`\n${chalk.cyan.bold(`🧠 ${personaLabel} Response:`)}\n`);

  parts.forEach((part, i) => {
    if (i % 2 === 0) {
      // Explanation text (non-code block) — shown in plain white.
      console.log(chalk.white(part.trim()));
    } else {
      // SAS code block — shown in bright green for visibility.
      console.log(chalk.greenBright("\n" + part.trim() + "\n"));
    }
  });

  // Display a separator after the full response for readability.
  console.log(chalk.gray('────────────────────────────────────────────'));
}

/**
 * Why This Design Works:
 *
 * - Separation of Concerns:
 *   This module is responsible only for how content is displayed,
 *   not how it’s generated or sourced.
 *
 * - UX-Oriented:
 *   Color-coded formatting clearly separates explanations from code,
 *   improving readability and user experience in the terminal.
 *
 * - Maintainability:
 *   If output formats change (e.g., to markdown, HTML, or logs),
 *   this is the only place that needs to be updated.
 *
 * - Reusability:
 *   Can be used in other CLI tools or as part of a logging system
 *   with no changes to core logic.
 *
 * - SOLID Compliant:
 *   The function has a single, clear responsibility — formatting responses.
 */
