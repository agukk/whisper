import Foundation
import AppKit

// MARK: - ActiveWindowInfo（Unit 3 境界インターフェース）

/// アクティブウィンドウの情報を表す値オブジェクト
struct ActiveWindowInfo {
    /// アクティブなアプリケーション名
    let applicationName: String
    /// アクティブなウィンドウのタイトル
    let windowTitle: String
    /// プロセスID
    let processIdentifier: pid_t
}

// MARK: - ActiveWindowService

/// macOS のアクティブウィンドウ情報を取得するサービス。
/// Unit 3（テキスト処理・出力）への境界インターフェースとして機能する。
@MainActor
final class ActiveWindowService: ObservableObject {

    // MARK: - 振る舞い

    /// 現在アクティブなウィンドウの情報を取得する
    func getActiveWindowInfo() -> ActiveWindowInfo? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            print("[ActiveWindowService] No frontmost application found")
            return nil
        }

        let appName = frontApp.localizedName ?? "Unknown"
        let pid = frontApp.processIdentifier

        // ウィンドウタイトルは Accessibility API が必要だが、スタブでは簡易版を使用
        let windowTitle = appName

        let info = ActiveWindowInfo(
            applicationName: appName,
            windowTitle: windowTitle,
            processIdentifier: pid
        )

        print("[ActiveWindowService] Active window: \(appName) (PID: \(pid))")
        return info
    }
}
