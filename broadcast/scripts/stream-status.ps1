# stream-status.ps1 — 看推流狀態
#
# 執行：powershell -File <repo>\broadcast\scripts\stream-status.ps1

$broadcastRoot = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent
$logDir = "$broadcastRoot\logs"

"=== 推流狀態 ==="

# ffmpeg 狀態
$ffmpegPidFile = "$logDir\ffmpeg.pid"
if (Test-Path $ffmpegPidFile) {
    $pid_ = (Get-Content $ffmpegPidFile).Trim()
    $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
    if ($proc) {
        $uptime = (Get-Date) - $proc.StartTime
        "ffmpeg : 運行中 (PID=$pid_, 已跑 $([math]::Round($uptime.TotalMinutes, 1)) 分鐘)"
        "  CPU: $([math]::Round($proc.CPU, 1))s, RAM: $([math]::Round($proc.WS / 1MB, 1)) MB"
    } else {
        "ffmpeg : 不在跑（PID 檔還在但 process 已死，可能 crash）"
    }
} else {
    "ffmpeg : 未啟動"
}

# Chrome 狀態
$chromePidFile = "$logDir\chrome.pid"
if (Test-Path $chromePidFile) {
    $pid_ = (Get-Content $chromePidFile).Trim()
    $proc = Get-Process -Id $pid_ -ErrorAction SilentlyContinue
    if ($proc) {
        "Chrome : 運行中 (PID=$pid_)"
    } else {
        "Chrome : 不在跑"
    }
} else {
    "Chrome : 未啟動"
}

# 最近 ffmpeg log
"`n=== 最近一份 ffmpeg log（末 15 行）==="
$latestLog = Get-ChildItem "$logDir\ffmpeg-*.log" -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latestLog) {
    "檔案：$($latestLog.Name) ($([math]::Round($latestLog.Length / 1KB, 1)) KB)"
    Get-Content $latestLog.FullName -Tail 15
} else {
    "(無 ffmpeg log)"
}

# 最近 stream.log
"`n=== stream.log 末 5 行 ==="
if (Test-Path "$logDir\stream.log") {
    Get-Content "$logDir\stream.log" -Tail 5
} else {
    "(無 stream.log)"
}
