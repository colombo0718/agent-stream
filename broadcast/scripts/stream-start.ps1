# stream-start.ps1 - Launch Chrome + ffmpeg, push to YouTube
# Usage: powershell -ExecutionPolicy Bypass -File <repo>\broadcast\scripts\stream-start.ps1
# Optional: -Url "https://example.com"

param(
    [string]$Url = "https://leaflune.org/",
    [int]$Width = 1920,
    [int]$Height = 1080,
    [int]$Fps = 30,
    [int]$BitrateKbps = 4500,
    [switch]$NoAudio
)

$ErrorActionPreference = "Stop"

# Detect broadcast root (one level up from scripts/)
$broadcastRoot = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent

# 1. Read stream key
$keyFile = "$broadcastRoot\secrets\youtube-stream-key.txt"
if (-not (Test-Path $keyFile)) {
    Write-Error "Stream key not found: $keyFile"
    exit 1
}
$streamKey = (Get-Content $keyFile -Raw).Trim()
if (-not $streamKey) {
    Write-Error "Stream key file is empty: $keyFile"
    exit 1
}
$rtmpUrl = "rtmp://a.rtmp.youtube.com/live2/$streamKey"

# 2. Kill any leftover ffmpeg
Get-Process -Name "ffmpeg" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 3. Launch Chrome (app mode = no toolbar/url-bar)
$chromeExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromeExe)) {
    Write-Error "Chrome not at $chromeExe"
    exit 1
}

$chromeArgs = @(
    "--app=$Url"
    "--window-position=0,0"
    "--window-size=$Width,$Height"
    "--no-first-run"
    "--no-default-browser-check"
    "--disable-features=Translate,TranslateUI"
    "--user-data-dir=$broadcastRoot\chrome-profile"
)

$logDir = "$broadcastRoot\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Launch Chrome -> $Url" | Tee-Object -FilePath "$logDir\stream.log" -Append

$chromeProc = Start-Process $chromeExe -ArgumentList $chromeArgs -PassThru
Start-Sleep -Seconds 5

# 4. ffmpeg: gdigrab capture + NVENC + push to YouTube
$ffmpegLog = "$logDir\ffmpeg-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

$videoArgs = @(
    "-f", "gdigrab"
    "-framerate", "$Fps"
    "-offset_x", "0"
    "-offset_y", "0"
    "-video_size", "${Width}x${Height}"
    "-i", "desktop"
)

# Audio: silent track for now (YouTube needs an audio track even if silent)
$audioArgs = @()
if (-not $NoAudio) {
    $audioArgs = @("-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=44100")
    # Future (after VB-Cable installed):
    # $audioArgs = @("-f", "dshow", "-i", "audio=CABLE Output (VB-Audio Virtual Cable)")
}

$encodeArgs = @(
    "-c:v", "h264_nvenc"
    "-preset", "p4"
    "-tune", "hq"
    "-rc", "cbr"
    "-b:v", "${BitrateKbps}k"
    "-maxrate", "${BitrateKbps}k"
    "-bufsize", "$($BitrateKbps * 2)k"
    "-pix_fmt", "yuv420p"
    "-g", "$($Fps * 2)"
    "-c:a", "aac"
    "-b:a", "128k"
    "-ar", "44100"
    "-f", "flv"
    $rtmpUrl
)

$allArgs = $videoArgs + $audioArgs + $encodeArgs

"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Launch ffmpeg" | Tee-Object -FilePath "$logDir\stream.log" -Append

$ffmpegProc = Start-Process -FilePath "ffmpeg" -ArgumentList $allArgs `
    -RedirectStandardError $ffmpegLog `
    -WindowStyle Hidden `
    -PassThru

Start-Sleep -Seconds 3

# 5. Save PIDs for stop script
$ffmpegProc.Id | Out-File "$logDir\ffmpeg.pid" -Encoding ASCII
$chromeProc.Id | Out-File "$logDir\chrome.pid" -Encoding ASCII

# 6. Confirm ffmpeg running
$running = Get-Process -Id $ffmpegProc.Id -ErrorAction SilentlyContinue
if ($running) {
    "[OK] ffmpeg PID=$($ffmpegProc.Id) running"
    "URL: $Url"
    "Resolution: ${Width}x${Height}@${Fps}fps"
    "Bitrate: ${BitrateKbps}k"
    if ($NoAudio) { "Audio: none" } else { "Audio: silent placeholder" }
    "Log: $ffmpegLog"
    "Wait ~30s, then check YouTube Studio for incoming stream."
} else {
    "[FAIL] ffmpeg did not start"
    if (Test-Path $ffmpegLog) {
        "--- log tail ---"
        Get-Content $ffmpegLog -Tail 30
    }
    exit 1
}
