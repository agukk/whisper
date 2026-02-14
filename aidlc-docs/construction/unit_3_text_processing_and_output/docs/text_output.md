# TextOutput（テキスト出力）

## 概要

リライト処理後のテキストを外部アプリケーションに出力するドメインモデル。デフォルトではアクティブなテキストフィールドへの直接入力を行い、クリップボードコピーは独立した追加アクションとして存在する。ユーザーは設定で出力方法を切り替えることもできる。

対応ユーザーストーリー: **US-007**（クリップボードコピー）、**US-010**（アクティブなテキストフィールドへの直接入力）

---

## コンポーネント種別

**エンティティ（Entity）**

---

## 属性

| 属性名 | 型 | 説明 |
|---|---|---|
| outputId | 一意識別子 | テキスト出力を一意に識別するID |
| text | 文字列 | 出力対象のテキスト（リライト後テキスト、またはリライト失敗時はrawテキスト） |
| outputMethod | OutputMethod（値オブジェクト） | 現在の出力方法の設定 |
| status | OutputStatus（値オブジェクト） | テキスト出力の現在状態 |

---

## 値オブジェクト

### OutputMethod（出力方法）

テキストの出力先を表す値オブジェクト。

| 値 | 説明 |
|---|---|
| ActiveField | アクティブなテキストフィールドへの直接入力（デフォルト） |
| Clipboard | クリップボードへのコピーのみ |
| Both | アクティブフィールド入力とクリップボードコピーの両方 |

### OutputStatus（出力状態）

テキスト出力処理の状態を表す値オブジェクト。

| 値 | 説明 |
|---|---|
| Pending | 出力待ち |
| Outputting | 出力処理中 |
| Completed | 出力完了 |
| Failed | 出力失敗 |

---

## 振る舞い

| メソッド | 説明 | 事前条件 | 事後条件 |
|---|---|---|---|
| outputToActiveField(text, activeWindowInfo) | アクティブなテキストフィールドにテキストを入力する | activeWindowInfo が有効であること | テキストがアクティブフィールドに追記され、status が Completed に遷移する |
| copyToClipboard(text) | テキストをクリップボードにコピーする | — | テキストがクリップボードにコピーされ、status が Completed に遷移する |
| executeOutput(text, activeWindowInfo) | outputMethod の設定に基づいて適切な出力処理を実行する | — | 設定に応じて outputToActiveField / copyToClipboard が呼び出される |
| setOutputMethod(method) | 出力方法を変更する | method が有効な OutputMethod であること | outputMethod が新しい値に更新される |

---

## ドメインイベント

| イベント名 | 発生タイミング | ペイロード | 備考 |
|---|---|---|---|
| TextOutputCompleted | executeOutput() 完了時 | outputId, text, outputMethod | 出力完了の通知（UIフィードバック表示のトリガー） |
| TextCopiedToClipboard | copyToClipboard() 完了時 | outputId, text | クリップボードコピー成功のフィードバック表示 |
| TextOutputFailed | 出力処理失敗時 | outputId, エラー情報 | エラーハンドリング |

---

## ビジネスルール

1. デフォルトの出力方法はアクティブフィールドへの直接入力（ActiveField）
2. クリップボードコピーはコピーボタンまたはキーボードショートカットによる独立したアクションとして常に利用可能
3. ユーザーは設定で出力方法を切り替えられる（ActiveField / Clipboard / Both）
4. アクティブフィールドへの入力は既存テキストへの追記（上書きしない）
5. Gemini Flash でリライトされた場合はリライト後のテキストが出力される
6. macOS の各種アプリケーション（テキストエディタ、ブラウザ、メールクライアント、チャットアプリなど）で動作すること
7. コピー成功時にはUIフィードバック（通知やUIの変化）が表示される
