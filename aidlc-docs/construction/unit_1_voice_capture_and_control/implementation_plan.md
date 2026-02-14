# Unit 1: 音声キャプチャ・操作制御 — 実装計画

## 確定済み技術仕様

| 項目 | 決定事項 |
|---|---|
| 言語 / フレームワーク | Swift + SwiftUI |
| プロジェクト管理 | Swift Package Manager（Package.swift） |
| 最小対応バージョン | macOS 14 Sonoma |
| アプリ名 | Whisper |
| Bundle Identifier | `com.nuxxx.whisper` |
| ショートカットキー | **fn（Globe）キー**の長押し |
| メニューバーアイコン | SF Symbols（`mic.fill` / `mic.slash.fill`） |
| Unit 2/3 結合 | スタブ（ログ出力のみ） |

---

## プロジェクト構成

```
Whisper/
├── Package.swift
├── Sources/
│   └── Whisper/
│       ├── App/
│       │   └── WhisperApp.swift          # エントリポイント（MenuBarExtra）
│       ├── Domain/
│       │   ├── VoiceCaptureSession.swift  # セッションエンティティ + CaptureStatus
│       │   ├── ShortcutConfiguration.swift # ショートカット設定（fn キー有効/無効）
│       │   └── ApplicationLifecycle.swift  # アプリライフサイクル + MenuBarDisplayState
│       ├── Views/
│       │   ├── MenuBarView.swift          # メニューバーポップオーバー
│       │   └── SettingsView.swift         # 設定画面
│       ├── Services/
│       │   ├── AudioCaptureService.swift   # マイク入力（AVAudioEngine）
│       │   ├── GlobalHotkeyService.swift   # fn キー監視
│       │   └── ActiveWindowService.swift   # アクティブウィンドウ情報取得
│       └── Resources/
│           └── Info.plist                 # 権限設定
└── Tests/
    └── WhisperTests/
        ├── VoiceCaptureSessionTests.swift
        └── ShortcutConfigurationTests.swift
```

---

## 実装ファイル詳細

### ドメイン層

#### [NEW] VoiceCaptureSession.swift

- `CaptureStatus` enum: `.idle`, `.recording`, `.processing`
- `VoiceCaptureSession` class: `startCapture()`, `stopCapture()`, `complete()`
- 状態遷移ルール、ドメインイベント通知（Combine `PassthroughSubject` 使用）

#### [NEW] ShortcutConfiguration.swift

- fn（Globe）キー固定のショートカット設定
- `isEnabled` による有効/無効切り替え
- キー変更機能は不要（fn キー固定のため）

#### [NEW] ApplicationLifecycle.swift

- `AppStatus` enum: `.active`, `.terminated`
- `MenuBarDisplayState` enum: `.idle`, `.recording`
- `updateIconState(captureStatus:)` でセッション状態とアイコン表示を連動

---

### UI 層

#### [NEW] WhisperApp.swift

- `@main` エントリポイント
- `MenuBarExtra` でメニューバー常駐（macOS 14+）
- Dock 非表示設定（`LSUIElement = true`）

#### [NEW] MenuBarView.swift

- プッシュトゥトークボタン（押し続けで録音開始、離すと停止）
- 録音状態の視覚フィードバック（色変化、アニメーション）
- 設定・終了メニュー

#### [NEW] SettingsView.swift

- fn キーショートカットの有効/無効切り替えトグル

---

### サービス層

#### [NEW] AudioCaptureService.swift

- `AVAudioEngine` でマイク入力をキャプチャ
- Protocol で Unit 2 向け境界インターフェース（`AudioStreamOutput`）を定義
- スタブ実装: キャプチャしたデータはログ出力のみ

#### [NEW] GlobalHotkeyService.swift

- `NSEvent.addGlobalMonitorForEvents` で fn（Globe）キーの押下/解放を監視
- キーダウン → `VoiceCaptureSession.startCapture()`
- キーアップ → `VoiceCaptureSession.stopCapture()`

#### [NEW] ActiveWindowService.swift

- macOS Accessibility API でアクティブウィンドウ情報を取得
- Protocol で Unit 3 向け境界インターフェース（`ActiveWindowInfo`）を定義
- スタブ実装: 取得した情報はログ出力のみ

---

### プロジェクト設定

#### [NEW] Package.swift

- macOS 14+ ターゲット
- 実行可能ターゲット `Whisper` + テストターゲット `WhisperTests`

#### [NEW] Info.plist

- `NSMicrophoneUsageDescription`: マイクアクセスの理由
- `LSUIElement`: Dock 非表示
- Bundle Identifier: `com.nuxxx.whisper`

---

## 検証計画

### 自動テスト

```bash
swift test  # ドメインモデルのユニットテスト
swift build # ビルド成功の確認
```

- `VoiceCaptureSessionTests`: 状態遷移（Idle→Recording→Processing→Idle）、不正遷移の拒否
- `ShortcutConfigurationTests`: enable / disable

### 手動検証

1. メニューバーにマイクアイコン（`mic.fill`）が表示されることを確認
2. メニューバーのボタン押し続け → 録音状態に遷移 → 離す → 停止を確認
3. fn キー長押し → 録音開始、fn キー解放 → 停止をログで確認
4. 設定画面で fn キーショートカットの有効/無効を切り替えられることを確認

> **注意:** Unit 2（音声認識エンジン）はまだ未実装のため、音声ストリームの送信先はスタブ（ログ出力のみ）で代替します。

---

## 実装ステップ

- [x] ステップ 1: プロジェクト作成（Package.swift, ディレクトリ構成）
- [x] ステップ 2: ドメイン層の実装（VoiceCaptureSession, ShortcutConfiguration, ApplicationLifecycle）
- [x] ステップ 3: ドメイン層のユニットテスト（作成済み。実行には Xcode が必要）
- [x] ステップ 4: サービス層の実装（AudioCaptureService, GlobalHotkeyService, ActiveWindowService）
- [x] ステップ 5: UI 層の実装（WhisperApp, MenuBarView, SettingsView）
- [ ] ステップ 6: 結合・手動検証（Xcode インストール後に実施）
