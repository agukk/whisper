import Foundation
import Combine

// MARK: - CaptureStatus（録音状態）

/// 音声キャプチャセッションの状態を表す値オブジェクト
enum CaptureStatus: Equatable {
    /// 待機中（録音していない）
    case idle
    /// 録音中（ボタン/キーが押されている）
    case recording
    /// 停止処理中（ボタンを離した直後、音声データを認識エンジンへ送信中）
    case processing
}

// MARK: - ドメインイベント

/// VoiceCaptureSession が発行するドメインイベント
enum CaptureEvent {
    /// 音声キャプチャが開始された
    case captureStarted(sessionId: UUID, startedAt: Date)
    /// 音声キャプチャが停止された
    case captureStopped(sessionId: UUID, stoppedAt: Date)
    /// セッションが完了した
    case captureCompleted(sessionId: UUID)
}

// MARK: - VoiceCaptureSession（音声キャプチャセッション）

/// 音声入力の1回のセッション（開始→録音→停止）を表すエンティティ。
/// ユーザーがプッシュトゥトーク操作を行うたびに状態が遷移する。
///
/// ## 状態遷移
/// ```
/// Idle → Recording → Processing → Idle
/// ```
///
/// ## ビジネスルール
/// - セッションは常に Idle → Recording → Processing → Idle の順で遷移する（スキップ不可）
/// - 同時に複数のセッションを Recording 状態にすることはできない
/// - ボタン/キーを「押し続けている間」のみ Recording 状態を維持する（プッシュトゥトーク）
@MainActor
final class VoiceCaptureSession: ObservableObject {

    // MARK: - 属性

    let sessionId: UUID
    @Published private(set) var status: CaptureStatus
    private(set) var startedAt: Date?
    private(set) var stoppedAt: Date?

    // MARK: - ドメインイベントパブリッシャー

    let eventPublisher = PassthroughSubject<CaptureEvent, Never>()

    // MARK: - 初期化

    init(sessionId: UUID = UUID()) {
        self.sessionId = sessionId
        self.status = .idle
    }

    // MARK: - 振る舞い

    /// 音声キャプチャを開始する
    /// - Precondition: status が .idle であること
    /// - Postcondition: status が .recording に遷移し、マイクからの音声入力が開始される
    func startCapture() {
        guard status == .idle else {
            return
        }
        let now = Date()
        startedAt = now
        stoppedAt = nil
        status = .recording
        eventPublisher.send(.captureStarted(sessionId: sessionId, startedAt: now))
    }

    /// 音声キャプチャを停止する
    /// - Precondition: status が .recording であること
    /// - Postcondition: status が .processing に遷移し、音声データストリームが Unit 2 へ送信される
    func stopCapture() {
        guard status == .recording else {
            return
        }
        let now = Date()
        stoppedAt = now
        status = .processing
        eventPublisher.send(.captureStopped(sessionId: sessionId, stoppedAt: now))
    }

    /// セッションを完了する
    /// - Precondition: status が .processing であること
    /// - Postcondition: status が .idle に遷移する
    func complete() {
        guard status == .processing else {
            return
        }
        status = .idle
        eventPublisher.send(.captureCompleted(sessionId: sessionId))
    }
}
