# Unit 2: 音声認識エンジン — 実装計画

## 確定済み技術仕様

| 項目 | 決定事項 |
|---|---|
| 音声認識 API | Apple Speech Framework（`SFSpeechRecognizer`） |
| 日英混合認識方式 | **方式 A**: 日本語・英語の2つの `SFSpeechRecognizer` を並行実行 |
| 認識モード | サーバー認識 |
| 音声データ入力 | Unit 1 の `AVAudioPCMBuffer` を直接 `SFSpeechAudioBufferRecognitionRequest` に渡す |
| 追加権限 | `NSSpeechRecognitionUsageDescription` |

---

## プロジェクト構成（Unit 2 追加分）

```
Whisper/Sources/Whisper/
├── Domain/
│   ├── RecognitionResult.swift       # 認識結果エンティティ + RecognitionSegment + Language
│   ├── LanguageConfiguration.swift   # 言語設定エンティティ
│   └── SpeechRecognitionSession.swift # 認識セッションエンティティ + RecognitionStatus
├── Services/
│   └── SpeechRecognitionService.swift # SFSpeechRecognizer を使った認識サービス
└── Views/
    └── SettingsView.swift            # [MODIFY] 言語設定UIを追加

Whisper/Tests/WhisperTests/
├── RecognitionResultTests.swift
├── LanguageConfigurationTests.swift
└── SpeechRecognitionSessionTests.swift
```

---

## 実装ファイル詳細

### ドメイン層

#### [NEW] RecognitionResult.swift

- `Language` enum: `.japanese`, `.english`
- `RecognitionSegment` struct（値オブジェクト）: `text`, `language`, `order`
- `RecognitionResult` class（エンティティ）: `addSegment()`, `getFullText()`, `getSegmentsByLanguage()`
- `RecognitionCompleted` ドメインイベント（Combine `PassthroughSubject`）

#### [NEW] LanguageConfiguration.swift

- `LanguageConfiguration` class（エンティティ）: `addLanguage()`, `removeLanguage()`, `isMultiLanguageEnabled()`
- ビジネスルール: 少なくとも1言語は常に有効、サポート言語は日本語・英語のみ
- ドメインイベント: `LanguageAdded`, `LanguageRemoved`

#### [NEW] SpeechRecognitionSession.swift

- `RecognitionStatus` enum: `.idle`, `.recognizing`, `.finalizing`, `.completed`, `.failed`
- `SpeechRecognitionSession` class: `startRecognition()`, `stopRecognition()`, `completeRecognition()`, `failRecognition()`
- ドメインイベント: `RecognitionStarted`, `RecognitionFinalized`, `RecognitionFailed`

---

### サービス層

#### [NEW] SpeechRecognitionService.swift

- 日本語用 `SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))` と英語用 `SFSpeechRecognizer(locale: Locale(identifier: "en-US"))` の2インスタンスを管理
- `AudioStreamOutput` プロトコルを実装し、Unit 1 の `AudioCaptureService` からバッファを受信
- 各言語の認識結果を `RecognitionSegment` に変換し、`RecognitionResult` を構築
- 認識完了時に `RecognitionFinalized` イベントを発行（Unit 3 への境界インターフェース）

---

### UI 層

#### [MODIFY] SettingsView.swift

- 言語設定セクションを追加（日本語 / 英語のトグル）
- `LanguageConfiguration` の `addLanguage` / `removeLanguage` と連動

---

### プロジェクト設定

#### [MODIFY] Package.swift

- 変更不要（`Speech` フレームワークは macOS SDK に含まれる）

---

## 検証計画

### 自動テスト

```bash
swift test
```

- `RecognitionResultTests`: セグメント追加、fullText 生成、言語別セグメント取得
- `LanguageConfigurationTests`: 言語の追加/削除、最低1言語ルール、重複追加拒否
- `SpeechRecognitionSessionTests`: 状態遷移（Idle→Recognizing→Finalizing→Completed）、失敗遷移

### 手動検証

1. 日本語で話しかけて認識結果がログに出力されることを確認
2. 英語で話しかけて認識結果がログに出力されることを確認
3. 日英混合で話しかけてセグメント分割されることを確認
4. 設定画面で言語の有効/無効を切り替えられることを確認

---

## 実装ステップ

- [x] ステップ 1: ドメイン層の実装（RecognitionResult, LanguageConfiguration, SpeechRecognitionSession）
- [x] ステップ 2: ドメイン層のユニットテスト（作成済み。実行には Xcode が必要）
- [x] ステップ 3: SpeechRecognitionService の実装（2つの SFSpeechRecognizer 並行実行）
- [x] ステップ 4: Unit 1 との結合（AudioStreamOutput 実装、AppCoordinator 接続）
- [x] ステップ 5: SettingsView に言語設定 UI を追加
- [x] ステップ 6: ビルド検証 ✅ 成功
