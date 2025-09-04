# ====================================================================================
# build.build.ps1 - Build Automation Script for SAS Copilot (Invoke-Build Compatible)
# ------------------------------------------------------------------------------------
# Purpose:
#   Defines standardized, reusable PowerShell build tasks using Invoke-Build.
#   Tasks include Docker image build, container execution, shell access, and cleanup:
#     - Build        : Build Docker image
#     - Run          : Run container (auto-prunes logs after exit)
#     - Clean        : Remove all log files (hard clean)
#     - LogsPrune    : Prune log files using retention from .env (minutes > days)
#     - DockerPrune  : Prune containers, images, volumes, builder cache (with before/after stats)
#     - PruneAll     : Run DockerPrune + LogsPrune
#     - Shell        : Interactive shell into the container
#     - Help         : Show helpful docker shell commands
#
# Behavior:
#   Dynamically loads configuration from .env file (if present) and applies fallback defaults.
#   Ensures Invoke-Build module is installed before proceeding.
#
# Dependencies:
#   - Docker Desktop (Linux container mode)
#   - PowerShell (5.1+ or Core)
#   - InvokeBuild module (installed if missing)
#   - .env file for centralized config (IMAGE_NAME, LOG_DIR, LOG_RETENTION_MINUTES/DAYS, etc.)
#
# Usage Examples:
#   Invoke-Build Build          # Build Docker image
#   Invoke-Build Run            # Build (if needed) and run container; prunes logs on exit
#   Invoke-Build Clean          # Delete all logs (no retention)
#   Invoke-Build LogsPrune      # Prune logs per .env retention (minutes preferred over days)
#   Invoke-Build DockerPrune    # Prune docker containers/images/volumes/builder caches
#   Invoke-Build PruneAll       # DockerPrune + LogsPrune
#   Invoke-Build Shell          # Open an interactive shell in container
#   Invoke-Build Help           # View docker shell reference commands
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
    # Resolve Windows path
    $windowsLogPath = (Resolve-Path "$PSScriptRoot\$LogDir").Path

    # Detect Docker engine OSType (linux/windows). Default to linux.
    $osType = & docker info --format '{{.OSType}}' 2>$null
    if (-not $osType) { $osType = 'linux' }

    if ($osType -eq 'linux') {
        # Convert C:\path\to\logs -> /mnt/c/path/to/logs
        $drive = $windowsLogPath.Substring(0,1).ToLower()
        $rest  = $windowsLogPath.Substring(3).Replace('\','/')
        $logPath = "/mnt/$drive/$rest"
    } else {
        # Windows containers: use native path
        $logPath = $windowsLogPath
    }

    Write-Host "[Run] Running container with log volume at $logPath"
    docker run -it `
      --env-file .env `
      --mount type=bind,source="$logPath",target=/app/logs `
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
# Task: DockerPrune
# Prunes containers, images, volumes, and builder cache and shows before/after stats.
# ------------------------------------------------------------------------------------
task DockerPrune {
    Write-Host ">>> System (before pruning):"
    docker system df

    Write-Host ">>> Images (before pruning):"
    docker images

    Write-Host ">>> Pruning containers..."
    docker container prune -f

    Write-Host ">>> Pruning images..."
    docker image prune -f

    Write-Host ">>> Pruning volumes..."
    docker volume prune -f

    Write-Host ">>> Pruning builder..."
    docker builder prune -f

    Write-Host ">>> System (after pruning):"
    docker system df

    Write-Host ">>> Images (after pruning):"
    docker images
}

# ------------------------------------------------------------------------------------
# Task: LogsPrune
# Reuses clean-logs.ps1; reads LOG_RETENTION_MINUTES / LOG_RETENTION_DAYS from .env.
# ------------------------------------------------------------------------------------
task LogsPrune {
    $clean = Join-Path $PSScriptRoot 'clean-logs.ps1'
    if (-not (Test-Path $clean)) {
        throw "[LogsPrune] Missing $clean"
    }

    # Ensure .env is visible to the script (your clean script already loads it,
    # but making sure the current process has the env doesn't hurt).
    $envFile = Join-Path $PSScriptRoot '.env'
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^(\w+)=([^#]*)') {
                $name, $value = $matches[1], $matches[2].Trim()
                [System.Environment]::SetEnvironmentVariable($name, $value, 'Process')
            }
        }
    }

    Write-Host "[LogsPrune] Running clean-logs.ps1…"
    & $clean
}

# ------------------------------------------------------------------------------------
# Task: PruneAll
# Aggregate task: run DockerPrune + LogsPrune in sequence.
# ------------------------------------------------------------------------------------
task PruneAll DockerPrune, LogsPrune

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