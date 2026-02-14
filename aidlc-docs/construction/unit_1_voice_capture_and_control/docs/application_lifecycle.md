# ApplicationLifecycle（アプリケーションライフサイクル）

## 概要

macOS メニューバーに常駐するアプリケーションのライフサイクルを管理するドメインモデル。バックグラウンド動作、メニューバー常駐、および設定画面へのアクセスを制御する。

対応ユーザーストーリー: **US-008**（アプリのメニューバー常駐）

---

## コンポーネント種別

**エンティティ（Entity）**

---

## 属性

| 属性名 | 型 | 説明 |
|---|---|---|
| appStatus | AppStatus（値オブジェクト） | アプリケーションの現在の状態 |
| menuBarIcon | MenuBarIcon（値オブジェクト） | メニューバーに表示するアイコンの状態 |

---

## 値オブジェクト

### AppStatus（アプリケーション状態）

アプリケーションの動作状態を表す値オブジェクト。

| 値 | 説明 |
|---|---|
| Active | アプリケーションがアクティブに動作中（フォアグラウンドまたはバックグラウンド） |
| Terminated | アプリケーションが終了済み |

### MenuBarIcon（メニューバーアイコン）

メニューバーに表示されるアイコンの視覚的状態を表す値オブジェクト。

| 属性名 | 型 | 説明 |
|---|---|---|
| displayState | MenuBarDisplayState | アイコンの表示状態 |

### MenuBarDisplayState（メニューバー表示状態）

| 値 | 説明 |
|---|---|
| Idle | 待機中（録音していない） |
| Recording | 録音中（ユーザーがプッシュトゥトーク中） |

---

## 振る舞い

| メソッド | 説明 | 事前条件 | 事後条件 |
|---|---|---|---|
| launch() | アプリケーションを起動し、メニューバーに常駐させる | appStatus が Terminated であること | appStatus が Active に遷移し、メニューバーにアイコンが表示される |
| terminate() | アプリケーションを終了する | appStatus が Active であること | appStatus が Terminated に遷移し、メニューバーからアイコンが削除される |
| updateIconState(captureStatus) | VoiceCaptureSession の状態に応じてアイコンの表示状態を更新する | appStatus が Active であること | menuBarIcon の displayState が更新される |
| openSettings() | 設定画面を開く | appStatus が Active であること | 設定画面が表示される |

---

## ドメインイベント

| イベント名 | 発生タイミング | ペイロード | 備考 |
|---|---|---|---|
| ApplicationLaunched | launch() 実行時 | — | メニューバーへの常駐開始 |
| ApplicationTerminated | terminate() 実行時 | — | メニューバーからの削除 |
| SettingsOpened | openSettings() 実行時 | — | 設定画面の表示 |

---

## ビジネスルール

1. アプリケーションは常にメニューバーに常駐する（Dock には表示しない）
2. アプリケーションはバックグラウンドで動作し続ける
3. メニューバーアイコンのクリック（押し続け）でプッシュトゥトーク方式の音声入力が可能
4. メニューバーアイコンの表示は VoiceCaptureSession の録音状態と連動して変化する
5. メニューバーから設定画面（ShortcutConfiguration など）にアクセスできる
