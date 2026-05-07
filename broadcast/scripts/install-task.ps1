# install-task.ps1 - Register the stream-broadcaster scheduled task
# Run this ONCE per machine (admin PowerShell).
#
# After install, trigger streaming via:
#   schtasks /run /tn "stream-broadcaster"

$ErrorActionPreference = "Stop"
$broadcastRoot = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent
$xmlPath = "$broadcastRoot\tasks\stream-broadcaster.xml"

if (-not (Test-Path $xmlPath)) {
    Write-Error "Task XML not found: $xmlPath"
    exit 1
}

# Delete old task if exists
schtasks /query /tn "stream-broadcaster" 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    "Deleting existing task..."
    schtasks /delete /tn "stream-broadcaster" /f
}

# Register from XML
"Installing task from $xmlPath ..."
schtasks /create /tn "stream-broadcaster" /xml $xmlPath

if ($LASTEXITCODE -eq 0) {
    "[OK] Task 'stream-broadcaster' registered."
    ""
    "Trigger streaming with:"
    "  schtasks /run /tn `"stream-broadcaster`""
    ""
    "Stop streaming with:"
    "  schtasks /end /tn `"stream-broadcaster`""
    "  (or call stream-stop.ps1 directly to kill ffmpeg)"
} else {
    Write-Error "Task registration failed."
    exit 1
}
