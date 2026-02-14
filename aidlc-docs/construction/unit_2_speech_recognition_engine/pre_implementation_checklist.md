# Unit 2 実装開始前の確認事項

Unit 2（音声認識エンジン）の実装を開始するにあたり、事前に決定が必要な項目をまとめます。

---

## 1. 音声認識 API

### 1-1. Apple Speech Framework の使用

macOS には `Speech` フレームワーク（`SFSpeechRecognizer`）が標準搭載されています。日本語・英語の両方に対応しており、リアルタイム認識が可能です。

[Question] Apple Speech Framework（`SFSpeechRecognizer`）を使用する方針でよろしいですか？
[Answer]
はい、使用する方針で問題ありません。

### 1-2. 日英混合認識の実装方式

Apple の `SFSpeechRecognizer` は言語ごとに1つのインスタンスを作成する仕組みです。日英混合認識を実現するには、以下のいずれかの方式が考えられます。

| 方式 | メリット | デメリット |
|---|---|---|
| **A. 2つの SFSpeechRecognizer を並行実行** | 各言語の精度が高い | リソース消費が大きい。音声データの二重処理が必要 |
| **B. 1つの SFSpeechRecognizer で主要言語を認識し、後で言語判定** | シンプル。リソース消費が少ない | 精度がやや劣る可能性 |
| **C. 初回は単一言語で実装し、混合は後回し** | 最速で動作確認可能 | US-004（混合認識）が後回しになる |

[Question] どの方式で進めますか？（A / B / C）
[Answer]
Aでお願いします。
---

## 2. 認識精度・設定

### 2-1. オンデバイス認識 vs サーバー認識

`SFSpeechRecognizer` はオンデバイス認識とサーバー認識の両方をサポートしています。

| 方式 | メリット | デメリット |
|---|---|---|
| **オンデバイス** | ネットワーク不要、プライバシー保護 | 精度がやや低い（特に混合認識） |
| **サーバー** | 高精度 | ネットワーク必要。1日あたりの認識回数制限あり |
| **自動（デフォルト）** | 状況に応じて最適な方を選択 | 挙動が予測しにくい |

[Question] オンデバイス / サーバー / 自動 のどれを使いますか？
[Answer]
サーバー
---

## 3. Unit 1 との結合

### 3-1. Audio バッファの受け渡し

Unit 1 で定義済みの `AudioStreamOutput` プロトコルを実装します。`SFSpeechRecognizer` は `SFSpeechAudioBufferRecognitionRequest` を使用し、`AVAudioPCMBuffer` を直接受け取れます。

[Question] Unit 1 の `AudioCaptureService` から受け取った `AVAudioPCMBuffer` をそのまま `SFSpeechAudioBufferRecognitionRequest` に渡す方針で問題ありませんか？
[Answer]
問題ありません。
---

## 4. 権限

### 4-1. 音声認識の権限

`SFSpeechRecognizer` の使用には、マイクアクセスに加えて **音声認識の権限** が別途必要です。

| 権限 | 用途 |
|---|---|
| **NSSpeechRecognitionUsageDescription** | 音声認識機能の使用理由をユーザーに説明 |

[Question] この権限の追加に問題はありませんか？
[Answer]
問題ありません。
---

## 回答状況

| # | 項目 | 回答状況 |
|---|---|---|
| 1-1 | Apple Speech Framework 使用 | ⬜ 未回答 |
| 1-2 | 日英混合認識の実装方式 | ⬜ 未回答 |
| 2-1 | オンデバイス vs サーバー | ⬜ 未回答 |
| 3-1 | Audio バッファの受け渡し | ⬜ 未回答 |
| 4-1 | 音声認識の権限 | ⬜ 未回答 |
