import fs from 'fs';

const testLogPath = './logs/manual-test.txt';

try {
  fs.writeFileSync(testLogPath, `Manual write at ${new Date().toISOString()}\n`, { flag: 'a' });
  console.log('[Test] Successfully wrote to log file.');
} catch (err) {
  console.error('[Test] Failed to write to log file:', err.message);
}
