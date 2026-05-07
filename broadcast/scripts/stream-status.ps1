# stream-status.ps1 - Show streaming status
# Usage: powershell -ExecutionPolicy Bypass -File <repo>\broadcast\scripts\stream-status.ps1

$broadcastRoot = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent
$logDir = "$broadcastRoot\logs"

"=== Stream Status ==="

# ffmpeg
$ffmpegPidFile = "$logDir\ffmpeg.pid"
if (Test-Path $ffmpegPidFile) {
    $pid_ = (Get-Content $ffmpegPidFile).Trim()
    $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
    if ($proc) {
        $uptime = (Get-Date) - $proc.StartTime
        "ffmpeg : RUNNING (PID=$pid_, uptime=$([math]::Round($uptime.TotalMinutes, 1)) min)"
        "         CPU=$([math]::Round($proc.CPU, 1))s, RAM=$([math]::Round($proc.WS / 1MB, 1)) MB"
    } else {
        "ffmpeg : DEAD (PID file exists but process gone, possibly crashed)"
    }
} else {
    "ffmpeg : NOT_STARTED"
}

# Chrome
$chromePidFile = "$logDir\chrome.pid"
if (Test-Path $chromePidFile) {
    $pid_ = (Get-Content $chromePidFile).Trim()
    $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
    if ($proc) {
        "Chrome : RUNNING (PID=$pid_)"
    } else {
        "Chrome : DEAD"
    }
} else {
    "Chrome : NOT_STARTED"
}

"`n=== Latest ffmpeg log (last 15 lines) ==="
$latestLog = Get-ChildItem "$logDir\ffmpeg-*.log" -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latestLog) {
    "File: $($latestLog.Name) ($([math]::Round($latestLog.Length / 1KB, 1)) KB)"
    Get-Content $latestLog.FullName -Tail 15
} else {
    "(no ffmpeg log)"
}

"`n=== stream.log (last 5 lines) ==="
if (Test-Path "$logDir\stream.log") {
    Get-Content "$logDir\stream.log" -Tail 5
} else {
    "(no stream.log)"
}
