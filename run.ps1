##################################################################################################
# run.ps1 — Build and Run SAS Copilot Docker Container with Host-Mounted Log Volume
#
# This script is intended to:
#   1. Resolve and prepare the log directory for host-container sharing
#   2. Build the latest version of the Docker image for the SAS Copilot assistant
#   3. Run the container interactively, passing in:
#      - Environment configuration via `.env`
#      - Volume mount to persist logs on the host machine
#
# This script is designed to run in a Windows PowerShell environment with Docker Desktop.
#
# Why This Design Works:
# - Reproducible: Builds cleanly and runs the same on any machine with Docker + PowerShell
# - Configurable: Uses `.env` for secrets and runtime options
# - Portable: No need for Node.js or npm installed locally
# - Secure: Keeps API keys and logs off the image itself
##################################################################################################

# ------------------------------------------------------------------------------------------------
# STEP 1: Resolve the absolute path to the "logs" folder on the host machine
# ------------------------------------------------------------------------------------------------
# $PSScriptRoot is a built-in PowerShell variable that points to the current script directory.
# This ensures the logs path is always correct, regardless of where the script is run from.
# Resolve-Path returns a clean, fully-qualified path usable by Docker for volume mounting.
# ------------------------------------------------------------------------------------------------
# $logPath = (Resolve-Path "$PSScriptRoot\logs").Path

$windowsLogPath = (Resolve-Path "$PSScriptRoot\logs").Path
$logPath = $windowsLogPath -replace '\\', '/' -replace '^([A-Za-z]):', { "/mnt/$($args[0].ToLower())" }


# ------------------------------------------------------------------------------------------------
# STEP 2: Build the Docker image from the local Dockerfile
# ------------------------------------------------------------------------------------------------
# `-t sas-copilot` gives the image a human-readable tag.
# Docker will use the Dockerfile in the current directory (.) to build the image.
# This ensures you are always running the latest local code in an isolated environment.
# ------------------------------------------------------------------------------------------------
Write-Host "Building Docker image..."
docker build -t sas-copilot .


# ------------------------------------------------------------------------------------------------
# STEP 3: Run the Docker container interactively
# ------------------------------------------------------------------------------------------------
# - `-it`: Interactive terminal mode (so you can type prompts into the CLI)
# - `--env-file .env`: Passes environment variables from a file (API key, model, temperature, etc.)
# - `--mount`: Binds a local directory to the container so logs persist on the host.
#     • source=$logPath       — the fully qualified local directory path on Windows
#     • target=/app/logs      — the path inside the container where logs will be written
# - `sas-copilot`: The image name to run (must match tag in the build step)
# ------------------------------------------------------------------------------------------------
Write-Host "Running container with log volume at $logPath"
docker run -it `
  --env-file .env `
  --mount type=bind,source=$logPath,target=/app/logs `
  sas-copilot
