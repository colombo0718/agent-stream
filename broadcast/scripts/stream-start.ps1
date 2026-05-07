# stream-start.ps1 — 啟動 Chrome + ffmpeg 推流到 YouTube
#
# 執行：powershell -File <repo>\broadcast\scripts\stream-start.ps1
# 帶參數：-Url "https://leaflune.org"   覆寫預設網址

param(
    [string]$Url = "https://leaflune.org/",
    [int]$Width = 1920,
    [int]$Height = 1080,
    [int]$Fps = 30,
    [int]$BitrateKbps = 4500,
    [switch]$NoAudio
)

$ErrorActionPreference = "Stop"

# 自動偵測 broadcast 根目錄（腳本所在的上一層）
$broadcastRoot = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent

# 1. 讀串流金鑰
$keyFile = "$broadcastRoot\secrets\youtube-stream-key.txt"
if (-not (Test-Path $keyFile)) {
    Write-Error "找不到串流金鑰：$keyFile`n請先建立此檔，內容貼一行 YouTube 串流金鑰。"
    exit 1
}
$streamKey = (Get-Content $keyFile -Raw).Trim()
if (-not $streamKey) {
    Write-Error "串流金鑰檔案是空的：$keyFile"
    exit 1
}
$rtmpUrl = "rtmp://a.rtmp.youtube.com/live2/$streamKey"

# 2. 確認沒有舊的 ffmpeg 殘留
Get-Process -Name "ffmpeg" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 3. 啟動 Chrome（app 模式 = 無書籤、無網址列、純畫面）
$chromeExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromeExe)) {
    Write-Error "Chrome 不在 $chromeExe"
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

"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 啟動 Chrome → $Url" | Tee-Object -FilePath "$logDir\stream.log" -Append

$chromeProc = Start-Process $chromeExe -ArgumentList $chromeArgs -PassThru
Start-Sleep -Seconds 5

# 4. ffmpeg 命令 — gdigrab 抓全螢幕區域，NVENC 編碼推 YouTube
$ffmpegLog = "$logDir\ffmpeg-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

$videoArgs = @(
    "-f", "gdigrab"
    "-framerate", "$Fps"
    "-offset_x", "0"
    "-offset_y", "0"
    "-video_size", "${Width}x${Height}"
    "-i", "desktop"
)

# 音訊：第一階段先用無聲音軌（YouTube 要求要有音軌才接受推流）
$audioArgs = @()
if (-not $NoAudio) {
    $audioArgs = @("-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=44100")
    # 將來裝了 VB-Cable 後改成：
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

"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 啟動 ffmpeg 推流" | Tee-Object -FilePath "$logDir\stream.log" -Append

$ffmpegProc = Start-Process -FilePath "ffmpeg" -ArgumentList $allArgs `
    -RedirectStandardError $ffmpegLog `
    -WindowStyle Hidden `
    -PassThru

Start-Sleep -Seconds 3

# 5. 寫入 PID 檔讓 stop 腳本能找到
$ffmpegProc.Id | Out-File "$logDir\ffmpeg.pid" -Encoding ASCII
$chromeProc.Id | Out-File "$logDir\chrome.pid" -Encoding ASCII

# 6. 確認 ffmpeg 真的啟動
$running = Get-Process -Id $ffmpegProc.Id -ErrorAction SilentlyContinue
if ($running) {
    "[OK] ffmpeg PID=$($ffmpegProc.Id) 啟動"
    "URL: $Url"
    "Resolution: ${Width}x${Height}@${Fps}fps"
    "Bitrate: ${BitrateKbps}k"
    "Audio: $(if ($NoAudio) { '無' } else { '無聲音軌（暫時）' })"
    "log: $ffmpegLog"
    "建議 30 秒後到 YouTube Studio 看畫面"
} else {
    "[FAIL] ffmpeg 啟動失敗"
    if (Test-Path $ffmpegLog) {
        "--- log 末段 ---"
        Get-Content $ffmpegLog -Tail 30
    }
    exit 1
}
