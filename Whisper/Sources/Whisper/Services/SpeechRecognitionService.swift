import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - SpeechRecognitionService

/// Apple Speech Framework を使用した音声認識サービス。
/// 日本語・英語の2つの SFSpeechRecognizer を並行実行し、日英混合認識をサポートする。
@MainActor
final class SpeechRecognitionService: ObservableObject, AudioStreamOutput {

    // MARK: - 属性

    private let japaneseRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private let englishRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    private var japaneseRequest: SFSpeechAudioBufferRecognitionRequest?
    private var englishRequest: SFSpeechAudioBufferRecognitionRequest?
    private var japaneseTask: SFSpeechRecognitionTask?
    private var englishTask: SFSpeechRecognitionTask?

    private var japaneseText: String = ""
    private var englishText: String = ""

    private var languageConfiguration: LanguageConfiguration
    private var recognitionSession: SpeechRecognitionSession?

    /// 認識完了時のコールバック
    var onRecognitionCompleted: ((RecognitionResult) -> Void)?
    /// 認識失敗時のコールバック
    var onRecognitionFailed: ((Error) -> Void)?

    // MARK: - 初期化

    init(languageConfiguration: LanguageConfiguration) {
        self.languageConfiguration = languageConfiguration
    }

    // MARK: - 権限リクエスト

    /// 音声認識の権限をリクエストする
    static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    // MARK: - AudioStreamOutput プロトコル実装

    nonisolated func didReceiveAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        Task { @MainActor in
            japaneseRequest?.append(buffer)
            englishRequest?.append(buffer)
        }
    }

    nonisolated func didStartStream() {
        Task { @MainActor in
            startRecognition()
        }
    }

    nonisolated func didStopStream() {
        Task { @MainActor in
            stopRecognition()
        }
    }

    // MARK: - 認識制御

    /// 音声認識を開始する
    func startRecognition() {
        // セッションを作成
        let session = SpeechRecognitionSession(languageConfiguration: languageConfiguration)
        self.recognitionSession = session
        session.startRecognition()

        // リセット
        japaneseText = ""
        englishText = ""

        let enabledLanguages = languageConfiguration.getEnabledLanguages()

        // 日本語の認識を開始
        if enabledLanguages.contains(.japanese) {
            startJapaneseRecognition()
        }

        // 英語の認識を開始
        if enabledLanguages.contains(.english) {
            startEnglishRecognition()
        }

        print("[SpeechRecognitionService] Recognition started (languages: \(enabledLanguages))")
    }

    /// 音声認識を停止し、結果を確定する
    func stopRecognition() {
        recognitionSession?.stopRecognition()

        // リクエストを終了
        japaneseRequest?.endAudio()
        englishRequest?.endAudio()

        print("[SpeechRecognitionService] Recognition stopping, finalizing results...")

        // 少し待ってから結果を確定する（最後のバッファ処理を待つ）
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
            self.finalizeResults()
        }
    }

    // MARK: - Private

    private func startJapaneseRecognition() {
        guard let recognizer = japaneseRecognizer, recognizer.isAvailable else {
            print("[SpeechRecognitionService] Japanese recognizer not available")
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false // サーバー認識を使用
        self.japaneseRequest = request

        japaneseTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.japaneseText = result.bestTranscription.formattedString
                }
                if let error = error {
                    print("[SpeechRecognitionService] Japanese recognition error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func startEnglishRecognition() {
        guard let recognizer = englishRecognizer, recognizer.isAvailable else {
            print("[SpeechRecognitionService] English recognizer not available")
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false // サーバー認識を使用
        self.englishRequest = request

        englishTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.englishText = result.bestTranscription.formattedString
                }
                if let error = error {
                    print("[SpeechRecognitionService] English recognition error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func finalizeResults() {
        guard let session = recognitionSession else { return }

        let result = RecognitionResult()
        var order = 0

        // 日本語セグメントを追加
        if !japaneseText.isEmpty {
            result.addSegment(RecognitionSegment(
                text: japaneseText,
                language: .japanese,
                order: order
            ))
            order += 1
        }

        // 英語セグメントを追加
        if !englishText.isEmpty {
            result.addSegment(RecognitionSegment(
                text: englishText,
                language: .english,
                order: order
            ))
        }

        // 認識結果が空の場合はエラー
        if result.segments.isEmpty {
            let error = NSError(
                domain: "SpeechRecognitionService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "認識結果が空です"]
            )
            session.failRecognition(error: error)
            onRecognitionFailed?(error)
        } else {
            session.completeRecognition(with: result)
            onRecognitionCompleted?(result)
            print("[SpeechRecognitionService] Recognition completed: \(result.getFullText())")
        }

        // クリーンアップ
        cleanup()
    }

    private func cleanup() {
        japaneseTask?.cancel()
        englishTask?.cancel()
        japaneseTask = nil
        englishTask = nil
        japaneseRequest = nil
        englishRequest = nil
    }
}
