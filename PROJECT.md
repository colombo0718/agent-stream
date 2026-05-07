# PROJECT.md — agent-stream

## 這是什麼

Claude 的 Agent VTuber 直播間。獨立於任何遊戲，可與任何內容組合。

---

## 架構原則

`vtuber-stream.html` 和遊戲頁面完全解耦，協調邏輯在 MCP 層。

```
vtuber-stream.html   ← 只管顯示，不知道遊戲存在
index.html（遊戲）   ← 只管遊戲，不知道 VTuber 存在
combined-view.html   ← iframe 容器，負責版型組合
MCP layer            ← Claude 在外部協調兩個頁面
```

---

## 目錄結構

```
agent-stream/
├── vtuber-stream.html     # 直播間主頁（待建）
├── combined-view.html     # 組合版型（待建）
├── PROJECT.md
├── CLAUDE.md
├── docs/
│   └── claude-character-design.md  # 克勞德角色設定
└── avatar/
    ├── refs/              # 定裝照參考圖
    │   └── claude-halfbody-v1.png
    └── clips/             # WebM 動畫片段
        ├── idle_1.webm
        ├── idle_2.webm
        ├── talking.webm
        ├── thinking.webm
        └── ...
```

---

## 控制 API

```js
window.vtuberAPI = {
    say(text, emotion = 'neutral'),  // 顯示文字 + 觸發說話動畫
    setExpression(expr),             // 切換表情狀態
    playAction(action),              // 播一次性動作片段
}
```

---

## 開發路線

| 階段 | 工作 | 狀態 |
|------|------|------|
| 形象設計 | 討論造型 → 定裝照確認 | ✅ 完成 |
| 動畫生成 | 按清單逐一生成 WebM | 待開始 |
| vtuber-stream.html | 版型 + 切換邏輯 + vtuberAPI | 待開始 |
| vtuber MCP server | Playwright + FastMCP | 待開始 |
| combined-view.html | 組合測試 | 待開始 |
| TTS | 語音驅動嘴型 | 未來 |

---

## 相關專案

- 遊戲：`mage-dragon/`
- 遊戲計畫：`mage-dragon/agent-vtuber-plan.md`
