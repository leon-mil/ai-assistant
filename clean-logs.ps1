<#
.SYNOPSIS
  Deletes log files from the /logs directory based on retention period.

.DESCRIPTION
  This script is designed to clean up old `.log` files from the `logs/` directory
  based on a retention threshold defined by either:
    - Command-line arguments (`-retentionDays`, `-retentionMinutes`)
    - Environment variables in the `.env` file:
        LOG_RETENTION_DAYS
        LOG_RETENTION_MINUTES

  The script prefers `retentionMinutes` over `retentionDays` when both are defined.

.PARAMETER retentionDays
  Number of days to keep log files. Older logs will be deleted.

.PARAMETER retentionMinutes
  Number of minutes to keep log files. Older logs will be deleted.
  Takes precedence over `retentionDays`.

.EXAMPLE
  ./clean-logs.ps1 -retentionDays 3

.EXAMPLE
  ./clean-logs.ps1 -retentionMinutes 90

.EXAMPLE
  # Will read retention config from the `.env` file if no arguments are passed
  ./clean-logs.ps1

.NOTES
  - Default retention is 7 days if nothing is specified.
  - Deletes only files with `.log` extension.
  - Safe to run manually or as part of automated scripts.
#>

param(
  [int]$retentionDays,
  [int]$retentionMinutes
)

# =====================================================================================
# Step 1: Load environment variables from `.env` if no args were passed
# =====================================================================================

if (-not $retentionDays -and -not $retentionMinutes) {
  $envPath = "$PSScriptRoot\.env"

  if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
      if ($_ -match '^\s*([^#=]+)\s*=\s*(.+)\s*$') {
        [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), 'Process')
      }
    }

    # Load from environment only if CLI params are missing
    if ($env:LOG_RETENTION_MINUTES) {
      $retentionMinutes = [int]$env:LOG_RETENTION_MINUTES
    } elseif ($env:LOG_RETENTION_DAYS) {
      $retentionDays = [int]$env:LOG_RETENTION_DAYS
    }
  }
}

# =====================================================================================
# Step 2: Resolve the logs directory and cleanup threshold
# =====================================================================================

$logDir = Join-Path $PSScriptRoot "logs"

if (-not (Test-Path $logDir)) {
  Write-Host "❌ Log directory not found at: $logDir"
  exit 1
}

# Compute the threshold based on retention
$now = Get-Date
$threshold = $now.AddDays(-7)
$retentionDisplay = "7 days (default)"

if ($retentionMinutes -gt 0) {
  $threshold = $now.AddMinutes(-$retentionMinutes)
  $retentionDisplay = "$retentionMinutes minutes"
} elseif ($retentionDays -gt 0) {
  $threshold = $now.AddDays(-$retentionDays)
  $retentionDisplay = "$retentionDays days"
}

# =====================================================================================
# Step 3: Perform cleanup
# =====================================================================================

Write-Host "🧹 Cleaning logs older than $retentionDisplay in $logDir..."

$deleted = 0
Get-ChildItem -Path $logDir -File -Filter *.log | Where-Object {
  $_.LastWriteTime -lt $threshold
} | ForEach-Object {
  Write-Host "Deleting: $($_.FullName)"
  Remove-Item $_.FullName -Force
  $deleted++
}

if ($deleted -eq 0) {
  Write-Host "✔️ No logs were eligible for deletion."
} else {
  Write-Host "✔️ Deleted $deleted log file(s)."
}
