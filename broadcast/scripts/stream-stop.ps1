# stream-stop.ps1 - Stop streaming
# Usage: powershell -ExecutionPolicy Bypass -File <repo>\broadcast\scripts\stream-stop.ps1
# -KeepChrome flag: only kill ffmpeg, keep Chrome window

param(
    [switch]$KeepChrome
)

$broadcastRoot = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent
$logDir = "$broadcastRoot\logs"

# 1. Kill ffmpeg from PID file
$ffmpegPidFile = "$logDir\ffmpeg.pid"
if (Test-Path $ffmpegPidFile) {
    $pid_ = (Get-Content $ffmpegPidFile).Trim()
    $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
    if ($proc) {
        $proc | Stop-Process -Force
        "[OK] ffmpeg PID=$pid_ stopped"
    } else {
        "(ffmpeg PID $pid_ already gone)"
    }
    Remove-Item $ffmpegPidFile -Force
} else {
    "(no ffmpeg PID file)"
}

# 2. Cleanup any leftover ffmpeg
Get-Process -Name "ffmpeg" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# 3. Close Chrome unless flag
if (-not $KeepChrome) {
    $chromePidFile = "$logDir\chrome.pid"
    if (Test-Path $chromePidFile) {
        $pid_ = (Get-Content $chromePidFile).Trim()
        $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
        if ($proc) {
            $proc | Stop-Process -Force
            "[OK] Chrome PID=$pid_ stopped"
        }
        Remove-Item $chromePidFile -Force
    }

    # Sweep: kill chrome procs using broadcast chrome-profile
    Get-Process -Name "chrome" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            if ($cmd -and $cmd -match "agent-stream\\broadcast\\chrome-profile") {
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }
}

"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] stream stopped" | Tee-Object -FilePath "$logDir\stream.log" -Append
