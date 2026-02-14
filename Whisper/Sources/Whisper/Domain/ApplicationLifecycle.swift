import Foundation
import Combine

// MARK: - AppStatus（アプリケーション状態）

/// アプリケーションの動作状態を表す値オブジェクト
enum AppStatus: Equatable {
    /// アプリケーションがアクティブに動作中
    case active
    /// アプリケーションが終了済み
    case terminated
}

// MARK: - MenuBarDisplayState（メニューバー表示状態）

/// メニューバーアイコンの視覚的状態を表す値オブジェクト
enum MenuBarDisplayState: Equatable {
    /// 待機中（録音していない）
    case idle
    /// 録音中（ユーザーがプッシュトゥトーク中）
    case recording
}

// MARK: - ApplicationLifecycle（アプリケーションライフサイクル）

/// macOS メニューバーに常駐するアプリケーションのライフサイクルを管理するエンティティ。
///
/// ## ビジネスルール
/// - アプリケーションは常にメニューバーに常駐する（Dock には表示しない）
/// - アプリケーションはバックグラウンドで動作し続ける
/// - メニューバーアイコンの表示は VoiceCaptureSession の録音状態と連動して変化する
@MainActor
final class ApplicationLifecycle: ObservableObject {

    // MARK: - 属性

    @Published private(set) var appStatus: AppStatus
    @Published private(set) var menuBarDisplayState: MenuBarDisplayState

    // MARK: - 初期化

    init() {
        self.appStatus = .active
        self.menuBarDisplayState = .idle
    }

    // MARK: - 振る舞い

    /// VoiceCaptureSession の状態に応じてメニューバーアイコンの表示状態を更新する
    /// - Parameter captureStatus: VoiceCaptureSession の現在の状態
    func updateIconState(captureStatus: CaptureStatus) {
        switch captureStatus {
        case .recording:
            menuBarDisplayState = .recording
        case .idle, .processing:
            menuBarDisplayState = .idle
        }
    }

    /// メニューバーアイコンの SF Symbol 名を返す
    var menuBarIconName: String {
        switch menuBarDisplayState {
        case .idle:
            return "mic.fill"
        case .recording:
            return "mic.badge.plus"
        }
    }

    /// アプリケーションを終了する
    func terminate() {
        appStatus = .terminated
    }
}
