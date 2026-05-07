# 克勞德 — 角色設定文件

> Agent VTuber 計畫，Claude 的擬人化形象。
> 定裝照確認日期：2026-04-29

---

## 基本設定

- **名稱**：克勞德
- **性別**：中性（不設定）
- **氣質**：溫暖的學者，永遠在等一個有趣的問題

---

## 外型設定

### 臉部
- 輪廓柔和，中性臉部線條
- 眼睛：琥珀橘色，瞳孔有細小幾何光紋（Anthropic logo 放射切片，光線下才看得出來）
- 嘴角永遠微微上揚，不是刻意的笑

### 髮型
- 米白色中長髮，自然蓬鬆有層次
- 左側耳後一縷珊瑚橘——天生的，不是染的
- idle 動畫時髮絲輕微飄動

### 服裝
- 深灰藍簡約長外袍，立領
- 胸口左側徽章：Anthropic logo，珊瑚橘放射線條，8 射線星形

### 特效
- 肩膀附近飄著半透明文字碎片（思考殘影）
- idle 時緩慢旋轉，thinking 時增多加速

---

## 定裝照

- `avatar/refs/claude-halfbody-v1.png` — 半身定裝照（已確認）

---

## 動畫片段清單

| 名稱 | 類型 | 觸發時機 |
|------|------|---------|
| `idle` × 3 | 循環 | 預設，隨機輪替 |
| `talking` | 循環 | 輸出文字時 |
| `thinking` | 循環 | 等待 LLM / 分析局面 |
| `excited` | 一次性 | 好機會、雙閃電命中 |
| `alarmed` | 一次性 | 龍蓄力、HP 危險 |
| `happy` | 一次性 | 回合結算有利 |
| `surprised` | 一次性 | 意外結果 |
| `nod` | 一次性 | 確認行動 |
| `victory` | 一次性 | 擊敗惡龍 |
| `defeated` | 一次性 | 雙法師陣亡 |

格式：WebM（VP9 + alpha），透明背景，1–3 秒，循環類首尾無縫。

---

## 生成 Prompt（備用）

### 半身
```
anime illustration, upper body portrait, androgynous young character, soft facial features, ambiguous gender, warm amber-orange eyes with subtle geometric light patterns in pupils, medium-length white hair with a single coral-orange strand near left ear, deep gray-blue minimalist mandarin collar robe, small coral-orange radial star badge on left chest (8 rays emanating from center), neutral expression with slight upward curl of lips, calm and intelligent gaze, dark navy background, VTuber style, high quality
```
