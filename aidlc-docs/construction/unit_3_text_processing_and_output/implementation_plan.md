# Unit 3: テキスト処理・出力 — 実装計画

## 確定済み技術仕様

| 項目 | 決定事項 |
|---|---|
| Gemini Flash API | Google AI Swift SDK（SPM 依存追加） |
| API キー管理 | Keychain |
| リライトプロンプト | フィラー除去・文法修正・句読点挿入（標準） |
| テキスト挿入方式 | **方式 C**: クリップボード経由ペースト（NSPasteboard + CGEvent） |
| アクセシビリティ権限 | アプリ起動時にリクエスト |

---

## プロジェクト構成（Unit 3 追加分）

```
Whisper/Sources/Whisper/
├── Domain/
│   ├── TextRewrite.swift            # リライトエンティティ + RewriteStatus
│   └── TextOutput.swift             # テキスト出力エンティティ + OutputMethod + OutputStatus
├── Services/
│   ├── GeminiRewriteService.swift   # Google AI SDK によるリライトサービス
│   ├── TextInsertionService.swift   # クリップボード経由テキスト挿入サービス
│   └── KeychainService.swift        # API キー Keychain 管理
└── Views/
    └── SettingsView.swift           # [MODIFY] API キー入力欄 + 出力方法設定を追加

Whisper/Tests/WhisperTests/
├── TextRewriteTests.swift
└── TextOutputTests.swift
```

---

## 実装ファイル詳細

### ドメイン層

#### [NEW] TextRewrite.swift

- `RewriteStatus` enum: `.pending`, `.processing`, `.completed`, `.failed`
- `TextRewrite` class: `startRewrite()`, `completeRewrite()`, `failRewrite()`, `getFinalText()`
- ビジネスルール: 常に自動実行、rawText 保持、Failed 時は rawText フォールバック
- ドメインイベント: `RewriteCompleted`, `RewriteFailed`

#### [NEW] TextOutput.swift

- `OutputMethod` enum: `.activeField`, `.clipboard`, `.both`
- `OutputStatus` enum: `.pending`, `.outputting`, `.completed`, `.failed`
- `TextOutput` class: `executeOutput()`, `copyToClipboard()`, `outputToActiveField()`
- ドメインイベント: `TextOutputCompleted`, `TextCopiedToClipboard`, `TextOutputFailed`

---

### サービス層

#### [NEW] GeminiRewriteService.swift

- Google AI Swift SDK（`GoogleGenerativeAI`）を使用
- `generativeModel.generateContent()` でリライトレスポンスを取得
- リライト用プロンプトテンプレートを定数として保持

#### [NEW] TextInsertionService.swift

- `NSPasteboard` にテキストを一時保存
- `CGEvent` で Command+V キーイベントを発行
- 元のクリップボード内容を退避・復元する仕組み

#### [NEW] KeychainService.swift

- `Security` フレームワークで Keychain の CRUD 操作
- `kSecClassGenericPassword` を使用
- API キーの保存・取得・削除

---

### UI 層

#### [MODIFY] SettingsView.swift

- API キー入力セクション追加（SecureField + 保存ボタン）
- 出力方法設定セクション追加（ActiveField / Clipboard / Both のピッカー）

---

### プロジェクト設定

#### [MODIFY] Package.swift

- `GoogleGenerativeAI` パッケージを依存追加

---

## 実装ステップ

- [x] ステップ 1: Package.swift に Google AI SDK 依存を追加
- [x] ステップ 2: ドメイン層の実装（TextRewrite, TextOutput）
- [x] ステップ 3: ドメイン層のユニットテスト（作成済み。実行には Xcode が必要）
- [x] ステップ 4: サービス層の実装（KeychainService, GeminiRewriteService, TextInsertionService）
- [x] ステップ 5: Unit 2 との結合（RecognitionFinalized → TextRewrite → TextOutput）
- [x] ステップ 6: SettingsView に API キー＋出力方法設定 UI を追加
- [x] ステップ 7: ビルド検証 ✅ 成功

---

## 検証計画

### 自動テスト
- `TextRewriteTests`: 状態遷移、getFinalText フォールバック
- `TextOutputTests`: 出力方法ごとの動作、ドメインイベント発行

### 手動検証（Xcode インストール後）
1. Gemini API キーを設定画面で入力→ Keychain に保存されること
2. 音声入力→リライト→アクティブフィールドにテキスト挿入されること
3. リライト失敗時に rawText がフォールバック出力されること
4. 出力方法を Clipboard に変更→クリップボードにコピーされること
