# Agent VTuber 計畫

Claude 作為 VTuber，有自己的直播間，可以獨立運作，也可以跟任何內容組合。

---

## 架構原則：完全解耦

`vtuber-stream.html` 和 `index.html`（遊戲）是兩個完全獨立的頁面，互相不知道對方存在。

```
vtuber-stream.html      ←→  完全獨立，可單獨打開
index.html（遊戲）      ←→  完全獨立，可單獨打開

combined-view.html      ←→  只是一個 iframe 容器，把兩者放在一起
```

「Claude 邊玩遊戲邊直播」這件事，是由 **Claude 的 MCP layer** 在外部協調的，不是頁面之間互相耦合。

---

## 傳統 VTuber vs Agent VTuber

| | 傳統 VTuber | Agent VTuber（Claude） |
|--|------------|----------------------|
| 驅動源 | 真人臉部 / 身體動作 | Claude 的決策與輸出 |
| 同步方式 | 動作捕捉（VSeeFace, VMC） | 狀態判斷 → 觸發片段 |
| 人偶角色 | 真人的「皮」 | Claude 的「臉」 |
| 聲音 | 真人聲音 | TTS（未來） |

傳統 VTuber 的人偶是輸出端，驅動源是人。  
這個專案反過來——先有 AI，為 AI 造一個有視覺存在感的形象。

---

## vtuber-stream.html

### 版型（豎屏）

```
┌─────────────────┐
│                 │
│  commentary     │  flex: 3
│  （對話泡泡）   │  文字逐字出現
│                 │  可捲動歷史
├─────────────────┤
│  [avatar]       │
│  Claude         │  flex: 1
└─────────────────┘
```

### 控制 API

頁面對外只暴露一個介面，**不含任何遊戲邏輯**：

```js
window.vtuberAPI = {
    say(text, emotion = 'neutral'),  // 顯示文字泡泡 + 觸發說話動畫
    setExpression(expr),             // 切換表情狀態（idle / thinking / alarmed…）
    playAction(action),              // 播一次性動作（nod / victory…）
}
```

外部的 MCP server 決定「什麼時候叫它說什麼」，頁面本身不做任何判斷。

---

## 形象設計

### 設計原則

- 這是 Claude 本身的形象，不是任何遊戲內角色
- 要有辨識度
- 半身構圖，適合豎屏版型

### 工作流程

1. **討論方向** → 確定風格（人形 / 擬人 / 抽象）、色系、氣質
2. **生成定裝照** → 用圖像生成工具，確定造型錨點
3. **定裝照確認** → 之後所有動畫以此為基準，確認後才生成
4. **生成動畫片段** → 逐一按清單製作 WebM

### 動畫片段清單

| 名稱 | 類型 | 說明 |
|------|------|------|
| `idle` × 2–3 | 循環 | 輕微呼吸、偶爾眨眼，多個變體隨機輪替 |
| `talking` | 循環 | 說話時的頭部微動 |
| `thinking` | 循環 | 歪頭 / 沉思 |
| `excited` | 一次性 | 向前傾、活潑 |
| `alarmed` | 一次性 | 眼睛睜大、反應 |
| `happy` | 一次性 | 笑 |
| `surprised` | 一次性 | 意外感 |
| `nod` | 一次性 | 點頭同意 |
| `victory` | 一次性 | 慶祝 |
| `defeated` | 一次性 | 沮喪 |

一次性片段播完後自動回 `idle`。

### 影片格式

**WebM（VP9 + alpha 通道）**，透明背景，每支 1–3 秒，循環類需首尾無縫。

---

## 跟其他內容的組合方式

iframe 容器頁面只管版型，不管邏輯：

```html
<!-- combined-view.html：範例，遊戲 + 直播 -->
<div style="display:flex; height:100vh">
    <iframe src="index.html"          style="flex:3"></iframe>
    <iframe src="vtuber-stream.html"  style="flex:1"></iframe>
</div>
```

未來可以輕鬆換成別的組合：
- 只開 `vtuber-stream.html`：純直播間
- 搭配其他遊戲：換掉左邊的 iframe
- 多個直播間並排：多個 vtuber iframe

---

## MCP 層（外部協調）

Claude 的 MCP server 各自獨立操控兩個頁面，協調邏輯在 MCP 層，不在頁面裡：

```python
# 玩遊戲的同時直播——Claude 自己決定說什麼
state = game_mcp.observe()

if state['dragon']['charging']:
    vtuber_mcp.say("龍在蓄力，要小心了……", emotion="alarmed")
    game_mcp.submit_action(2)  # 選護盾
    vtuber_mcp.play_action("nod")
else:
    vtuber_mcp.say("這回合可以出手！", emotion="excited")
    game_mcp.submit_action(1)  # 選閃電
```

vtuber MCP 和 game MCP 互相不知道對方存在，只有 Claude 知道兩者都在。

---

## 開發路線

| 階段 | 工作 | 依賴 |
|------|------|------|
| **形象設計** | 討論造型 → 生成定裝照 → 確認 | 無，現在就可以開始 |
| **動畫生成** | 按清單逐一生成 WebM 片段 | 定裝照確定後 |
| **vtuber-stream.html** | 版型 + 切換邏輯 + vtuberAPI | 有幾支測試片段就可以開始 |
| **vtuber MCP server** | Playwright + FastMCP，暴露 say / setExpression | 頁面完成後 |
| **組合測試** | combined-view.html，手動驗證兩個 iframe | 以上完成 |
| **TTS（未來）** | 文字 → 語音，驅動嘴型動畫 | 形象穩定後 |
