# ====================================================================================
# build.build.ps1 - Build Automation Script for SAS Copilot (Invoke-Build Compatible)
# ------------------------------------------------------------------------------------
# Purpose:
#   Defines standardized, reusable PowerShell build tasks using Invoke-Build.
#   Tasks include Docker image build, container execution, shell access, and log cleanup.
#
# Behavior:
#   Dynamically loads configuration from .env file (if present) and applies fallback defaults.
#   Ensures Invoke-Build module is installed before proceeding.
#
# Dependencies:
#   - Docker Desktop (Linux container mode)
#   - PowerShell (5.1+ or Core)
#   - InvokeBuild module (installed if missing)
#   - .env file for centralized config (IMAGE_NAME, LOG_DIR, etc.)
#
# Usage Examples:
#   Invoke-Build Build     # Build Docker image
#   Invoke-Build Run       # Build (if needed) and run container
#   Invoke-Build Clean     # Delete logs from log directory
#   Invoke-Build Shell     # Open an interactive shell in container
#   Invoke-Build Help      # View docker shell reference commands
# ====================================================================================

# ------------------------------------------------------------------------------------
# Ensure the Invoke-Build module is installed for task execution
# ------------------------------------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name InvokeBuild)) {
    Write-Host "[Init] Installing Invoke-Build module..."
    Install-Module -Name InvokeBuild -Force -Scope CurrentUser
}

# ------------------------------------------------------------------------------------
# Load environment variables from the .env file (if it exists)
# This enables centralized configuration across scripts and containers
# ------------------------------------------------------------------------------------
$envFile = "$PSScriptRoot/.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^(\w+)=([^#]*)') {
            $name, $value = $matches[1], $matches[2].Trim()
            [System.Environment]::SetEnvironmentVariable($name, $value)
        }
    }
}

# ------------------------------------------------------------------------------------
# Set global variables using values from .env or fallback defaults
# ------------------------------------------------------------------------------------
$ImageName = if ($env:IMAGE_NAME) { $env:IMAGE_NAME } else { 'sas-copilot' }   # Docker image name
$LogDir    = if ($env:LOG_DIR)    { $env:LOG_DIR }    else { 'logs' }          # Relative path to logs directory

# ====================================================================================
# TASK DEFINITIONS
# ====================================================================================

# ------------------------------------------------------------------------------------
# Task: Build
# Builds the Docker image using the current project context.
# ------------------------------------------------------------------------------------
task Build {
    Write-Host "[Build] Building Docker image..."
    docker build --no-cache -t $ImageName .
}

# ------------------------------------------------------------------------------------
# Task: Run (depends on Build)
# Builds (if needed) and runs the container with volume-mounted logs.
# ------------------------------------------------------------------------------------
task Run -If Build {
    $logPath = (Resolve-Path "$PSScriptRoot\$LogDir").Path
    Write-Host "[Run] Running container with log volume at $logPath"
    docker run -it `
      --env-file .env `
      --mount type=bind,source=$logPath,target=/app/logs `
      $ImageName
}

# ------------------------------------------------------------------------------------
# Task: Clean
# Deletes all `.log` files in the configured log directory.
# Useful for housekeeping before or after development sessions.
# ------------------------------------------------------------------------------------
task Clean {
    $fullLogPath = Join-Path $PSScriptRoot $LogDir
    if (Test-Path $fullLogPath) {
        Write-Host "[Clean] Removing log files in $fullLogPath"
        Get-ChildItem -Path $fullLogPath -File | Remove-Item -Force
    } else {
        Write-Host "[Clean] No log directory found to clean."
    }
}

# ------------------------------------------------------------------------------------
# Task: Shell
# Opens an interactive shell session inside the container for debugging or inspection.
# ------------------------------------------------------------------------------------
task Shell {
    Write-Host "[Shell] Opening interactive shell in Docker container..."
    docker run -it `
        --env-file .env `
        --mount type=bind,source="$PSScriptRoot/help",target=/app/help `
        $ImageName sh
}

# ------------------------------------------------------------------------------------
# Task: Help
# Displays helpful Docker shell commands from a curated script in the `help/` folder.
# Useful for quick lookup of common debugging, inspection, or development commands
# when working inside a running container via `Invoke-Build Shell`.
#
# The commands are maintained in `help/docker-shell-commands.sh` for:
#   - Reusability across host and container environments
#   - Easy sharing with other developers or team members
#   - Consistency in debugging workflows
#
# Usage:
#   Invoke-Build Help      # View docker shell reference commands
#
# Requirements:
#   - File: help/docker-shell-commands.sh must exist and be readable
#   - Can be extended to display other help files in the future
# ------------------------------------------------------------------------------------
task Help {
    Get-Content "$PSScriptRoot\help\docker-shell-commands.sh" | more
}