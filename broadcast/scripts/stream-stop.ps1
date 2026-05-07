# stream-stop.ps1 — 停止推流
#
# 執行：powershell -File <repo>\broadcast\scripts\stream-stop.ps1
# 加 -KeepChrome 只殺 ffmpeg，保留 Chrome 視窗

param(
    [switch]$KeepChrome
)

$broadcastRoot = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent
$logDir = "$broadcastRoot\logs"

# 1. 從 PID 檔殺 ffmpeg
$ffmpegPidFile = "$logDir\ffmpeg.pid"
if (Test-Path $ffmpegPidFile) {
    $pid_ = (Get-Content $ffmpegPidFile).Trim()
    $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
    if ($proc) {
        $proc | Stop-Process -Force
        "[OK] 停止 ffmpeg PID=$pid_"
    } else {
        "(ffmpeg PID $pid_ 已不存在)"
    }
    Remove-Item $ffmpegPidFile -Force
} else {
    "(無 ffmpeg PID 檔)"
}

# 2. 殺所有殘留的 ffmpeg
Get-Process -Name "ffmpeg" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# 3. 關 Chrome（除非保留）
if (-not $KeepChrome) {
    $chromePidFile = "$logDir\chrome.pid"
    if (Test-Path $chromePidFile) {
        $pid_ = (Get-Content $chromePidFile).Trim()
        $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
        if ($proc) {
            $proc | Stop-Process -Force
            "[OK] 關閉 Chrome PID=$pid_"
        }
        Remove-Item $chromePidFile -Force
    }

    # 額外清掃：殺所有用 broadcast chrome-profile 的 chrome
    Get-Process -Name "chrome" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            if ($cmd -and $cmd -match "agent-stream\\broadcast\\chrome-profile") {
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }
}

"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 推流停止" | Tee-Object -FilePath "$logDir\stream.log" -Append
