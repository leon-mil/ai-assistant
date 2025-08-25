# docker-shell-commands.sh
# =====================================================================
# Title: Interactive Docker Shell Commands Reference
# Purpose: Centralized and documented cheat sheet for useful commands
#          to execute inside the SAS Copilot container shell.
# Author: Leon (Columbia, MD)
# Usage: Run `Invoke-Build Shell` or equivalent to enter the container.
#        Then use the commands below for debugging, testing, and admin.
# =====================================================================

# ---------------------------------------------------------------------
# 1. Filesystem Navigation
# ---------------------------------------------------------------------
ls -al                    # List all files and directories (long format)
cd /app                  # Navigate to application root (container WORKDIR)
ls /app/logs             # Check the logs directory
pwd                      # Show current directory

# ---------------------------------------------------------------------
# 2. Environment Variable Inspection
# ---------------------------------------------------------------------
echo $OPENAI_API_KEY     # Verify current OpenAI API key
printenv                 # List all environment variables
echo $LOGGING_MODE       # Confirm current logging mode (rotate/append/overwrite)

# ---------------------------------------------------------------------
# 3. Application Runtime
# ---------------------------------------------------------------------
node index.js            # Start the assistant terminal manually inside Docker
node                     # Launch Node.js REPL for on-the-fly JavaScript testing

# ---------------------------------------------------------------------
# 4. Package Inspection
# --------------------------------------------------------------------
node -v                  # Show Node.js version
npm list                 # List installed npm packages (local)
npm list -g              # List globally installed packages (if applicable)
cat package.json         # View package metadata and dependencies

# ---------------------------------------------------------------------
# 5. Logs and Configuration
# ---------------------------------------------------------------------
cat .env                 # Print the current environment configuration file
cat /app/config/env.js   # Show runtime config mapping from env vars
ls /app/logs             # List all log files
cat /app/logs/session_*.log     # View specific log files
tail -f /app/logs/*.log  # Stream the latest log file in real-time

# ---------------------------------------------------------------------
# 6. File and Debugging Utilities
# ---------------------------------------------------------------------
touch test.txt           # Create a test file
echo "Hello Docker" > test.txt   # Write to file
cat test.txt             # Display file contents

# ---------------------------------------------------------------------
# 7. Log Management (optional)
# ---------------------------------------------------------------------
node clean-logs.ps1      # (Optional) Manually trigger log cleanup (PowerShell-based outside Docker)
rm -rf /app/logs/*.log   # Danger: Permanently deletes all logs

# ---------------------------------------------------------------------
# 8. Useful Diagnostic Tools
# ---------------------------------------------------------------------
which node               # Show path to Node binary
which npm                # Path to npm binary
ps aux                   # Show running processes inside container
netstat -tulpn           # List open network ports (install net-tools first)

# ---------------------------------------------------------------------
# 9. Exit Container Shell
# ---------------------------------------------------------------------
exit                     # Return to PowerShell or terminal on host machine

# ---------------------------------------------------------------------
# Notes:
# - This script is not executable. It is intended as an in-project
#   reference for developers working inside the container.
# - Feel free to copy/paste or alias useful commands in Dockerfiles
#   or runtime automation scripts.
# - Update this file as your environment or tooling evolves.
# ---------------------------------------------------------------------
