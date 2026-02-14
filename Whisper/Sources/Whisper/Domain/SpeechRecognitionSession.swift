import Foundation
import Combine

// MARK: - RecognitionStatus（認識処理状態）

/// 音声認識処理の現在状態を表す値オブジェクト
enum RecognitionStatus: Equatable {
    /// 待機中（音声データ未受信）
    case idle
    /// 認識中（音声データを受信し、リアルタイム認識処理中）
    case recognizing
    /// 最終化中（音声入力停止後、最終認識結果を確定中）
    case finalizing
    /// 完了（認識結果が確定済み）
    case completed
    /// 失敗（認識処理中にエラーが発生）
    case failed
}

// MARK: - ドメインイベント

/// SpeechRecognitionSession が発行するドメインイベント
enum RecognitionSessionEvent {
    /// 認識処理が開始された
    case recognitionStarted(sessionId: UUID, enabledLanguages: Set<Language>)
    /// 認識が完了し結果が確定した
    case recognitionFinalized(sessionId: UUID, result: RecognitionResult)
    /// 認識処理が失敗した
    case recognitionFailed(sessionId: UUID, error: Error)
}

// MARK: - SpeechRecognitionSession（音声認識セッション）

/// Unit 1 から受け取った音声データストリームを処理し、認識結果を生成する
/// ライフサイクルを管理するエンティティ。
///
/// ## 状態遷移
/// ```
/// Idle → Recognizing → Finalizing → Completed
///                  ↘        ↘
///                   Failed   Failed
/// ```
///
/// ## ビジネスルール
/// - VoiceCaptureSession と1対1で対応する
/// - LanguageConfiguration で設定された言語に基づいて動作する
/// - 複数言語が有効な場合は日英混合認識モードで動作する
@MainActor
final class SpeechRecognitionSession: ObservableObject {

    // MARK: - 属性

    let sessionId: UUID
    @Published private(set) var status: RecognitionStatus
    private let languageConfiguration: LanguageConfiguration
    @Published private(set) var result: RecognitionResult?

    // MARK: - ドメインイベントパブリッシャー

    let eventPublisher = PassthroughSubject<RecognitionSessionEvent, Never>()

    // MARK: - 初期化

    init(sessionId: UUID = UUID(), languageConfiguration: LanguageConfiguration) {
        self.sessionId = sessionId
        self.languageConfiguration = languageConfiguration
        self.status = .idle
    }

    // MARK: - 振る舞い

    /// 音声データストリームの受信を開始し、認識処理を開始する
    /// - Precondition: status が .idle であること
    func startRecognition() {
        guard status == .idle else { return }
        status = .recognizing
        eventPublisher.send(.recognitionStarted(
            sessionId: sessionId,
            enabledLanguages: languageConfiguration.getEnabledLanguages()
        ))
    }

    /// 音声データの受信を停止し、最終認識結果の確定処理に入る
    /// - Precondition: status が .recognizing であること
    func stopRecognition() {
        guard status == .recognizing else { return }
        status = .finalizing
    }

    /// 認識結果を確定する
    /// - Parameter recognitionResult: 確定した認識結果
    /// - Precondition: status が .finalizing であること
    func completeRecognition(with recognitionResult: RecognitionResult) {
        guard status == .finalizing else { return }
        self.result = recognitionResult
        status = .completed
        recognitionResult.finalize()
        eventPublisher.send(.recognitionFinalized(
            sessionId: sessionId,
            result: recognitionResult
        ))
    }

    /// 認識処理の失敗を記録する
    /// - Parameter error: 発生したエラー
    /// - Precondition: status が .recognizing または .finalizing であること
    func failRecognition(error: Error) {
        guard status == .recognizing || status == .finalizing else { return }
        status = .failed
        eventPublisher.send(.recognitionFailed(
            sessionId: sessionId,
            error: error
        ))
    }

    /// セッションをリセットして再利用可能にする
    func reset() {
        status = .idle
        result = nil
    }
}
