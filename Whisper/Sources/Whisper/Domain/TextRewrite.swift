import Foundation
import Combine

// MARK: - RewriteStatus（リライト処理状態）

/// リライト処理の状態を表す値オブジェクト
enum RewriteStatus: Equatable {
    /// リライト待ち（認識結果を受信済み、API呼び出し前）
    case pending
    /// リライト処理中（Gemini Flash API に送信中）
    case processing
    /// リライト完了（リライト後テキストが確定）
    case completed
    /// リライト失敗（API エラーなど）
    case failed
}

// MARK: - ドメインイベント

/// TextRewrite が発行するドメインイベント
enum TextRewriteEvent {
    /// リライト処理が開始された
    case rewriteStarted(rewriteId: UUID, rawText: String)
    /// リライトが完了した
    case rewriteCompleted(rewriteId: UUID, rawText: String, rewrittenText: String)
    /// リライトが失敗した（rawText をフォールバックとして使用）
    case rewriteFailed(rewriteId: UUID, error: Error)
}

// MARK: - TextRewrite（テキストリライト）

/// 音声認識で生成されたテキストを Gemini Flash API でリライト・精度補正するエンティティ。
/// リライトは常に自動で実行され、リライト前のテキスト（rawText）も保持する。
///
/// ## ビジネスルール
/// - リライトは常に自動実行（有効/無効の切替なし）
/// - rawText は常に保持される
/// - フィラーワード（えーと、あのー、um、uh）はリライト時に除去
/// - リライト失敗時は rawText をフォールバックとして使用
@MainActor
final class TextRewrite: ObservableObject {

    // MARK: - 属性

    let rewriteId: UUID
    let rawText: String
    @Published private(set) var rewrittenText: String?
    @Published private(set) var status: RewriteStatus
    let sourceRecognitionResultId: UUID

    // MARK: - ドメインイベントパブリッシャー

    let eventPublisher = PassthroughSubject<TextRewriteEvent, Never>()

    // MARK: - 初期化

    init(
        rewriteId: UUID = UUID(),
        rawText: String,
        sourceRecognitionResultId: UUID
    ) {
        self.rewriteId = rewriteId
        self.rawText = rawText
        self.sourceRecognitionResultId = sourceRecognitionResultId
        self.status = .pending
    }

    // MARK: - 振る舞い

    /// Gemini Flash API へテキストを送信し、リライト処理を開始する
    /// - Precondition: status が .pending であること
    func startRewrite() {
        guard status == .pending else { return }
        status = .processing
        eventPublisher.send(.rewriteStarted(rewriteId: rewriteId, rawText: rawText))
    }

    /// リライト結果を設定し、処理を完了する
    /// - Parameter rewrittenText: リライト後のテキスト
    /// - Precondition: status が .processing であること
    func completeRewrite(rewrittenText: String) {
        guard status == .processing else { return }
        self.rewrittenText = rewrittenText
        status = .completed
        eventPublisher.send(.rewriteCompleted(
            rewriteId: rewriteId,
            rawText: rawText,
            rewrittenText: rewrittenText
        ))
    }

    /// リライト処理の失敗を記録する
    /// - Parameter error: 発生したエラー
    /// - Precondition: status が .processing であること
    func failRewrite(error: Error) {
        guard status == .processing else { return }
        status = .failed
        eventPublisher.send(.rewriteFailed(rewriteId: rewriteId, error: error))
    }

    /// 最終的に使用するテキストを返す
    /// - Completed の場合は rewrittenText、それ以外は rawText
    func getFinalText() -> String {
        if status == .completed, let rewrittenText = rewrittenText {
            return rewrittenText
        }
        return rawText
    }

    /// リライト前の元テキストを返す
    func getRawText() -> String {
        return rawText
    }
}
