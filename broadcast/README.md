# broadcast — agent-stream 的直播廣播子系統

> 把 agent-stream 內容（vtuber-stream / combined-view / 或任意網頁）推流到 YouTube。
> **筆電維護程式碼，home 部署執行**——透過 git 同步，不直接傳檔。

---

## 部署流程（home 第一次設定）

```powershell
# 1. SSH 進 home
ssh home

# 2. clone agent-stream
mkdir D:\worker\projects 2>nul
cd D:\worker\projects
git clone <agent-stream GitHub URL> agent-stream

# 3. 放 YouTube 串流金鑰（這個檔案被 .gitignore，不在 repo 裡）
notepad D:\worker\projects\agent-stream\broadcast\secrets\youtube-stream-key.txt
# 貼一行金鑰 → 存檔

# 4. 第一次測試純畫面推流
powershell -File D:\worker\projects\agent-stream\broadcast\scripts\stream-start.ps1
```

---

## 日常使用流程

```powershell
# 開始推流（預設播 leaflune.org）
ssh home "powershell -File D:\worker\projects\agent-stream\broadcast\scripts\stream-start.ps1"

# 推流別的網址
ssh home "powershell -File D:\worker\projects\agent-stream\broadcast\scripts\stream-start.ps1 -Url 'https://reinroom.leaflune.org/'"

# 停止
ssh home "powershell -File D:\worker\projects\agent-stream\broadcast\scripts\stream-stop.ps1"

# 看狀態
ssh home "powershell -File D:\worker\projects\agent-stream\broadcast\scripts\stream-status.ps1"
```

---

## 程式碼維護流程

```
寫程式：    筆電 (C:\Users\USER\agent-stream\)
測試：      home (D:\worker\projects\agent-stream\)
同步：      git push 從筆電 → git pull 在 home

不傳檔，只傳 commit。
```

---

## 各腳本職責

| 腳本 | 用途 |
|------|------|
| `stream-start.ps1` | 啟動 Chrome 載入網頁 + 啟動 ffmpeg 推流 |
| `stream-stop.ps1` | 停止 ffmpeg、可選關閉 Chrome |
| `stream-status.ps1` | 看 ffmpeg 是否在跑、最近 log |
| `stream-watchdog.ps1`（未來）| 偵測 ffmpeg 死掉自動重啟 |

---

## 階段性目標

```
階段 0（現在）：
  純畫面推流，無音訊
  播 leaflune.org 證明管線通

階段 1：
  combined-view.html 簡化版
  iframe 組合：左 = 內容，右 = 空白

階段 2：
  vtuber-stream.html 最小版
  靜態頭像 + 文字氣泡，暴露 vtuberAPI.say()

階段 3：
  接 MCP 控制 vtuberAPI

階段 4：
  動畫片段、表情、TTS
```

---

## 已知坑（之後會踩到）

- VB-Cable 必須裝才能收系統音訊（軟體音、TTS、背景音樂）
- Windows Stereo Mix 是替代方案，多數新硬體驅動會藏起來
- ffmpeg gdigrab 抓的是螢幕區域，要確認 Chrome 視窗位置與大小固定
- NVENC 編碼省 CPU，但 GPU 6GB VRAM 要留給 LLM / 其他用途
