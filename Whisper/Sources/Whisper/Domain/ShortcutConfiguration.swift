import Foundation
import Combine

// MARK: - ドメインイベント

/// ShortcutConfiguration が発行するドメインイベント
enum ShortcutEvent {
    /// ショートカットが有効化された
    case shortcutEnabled
    /// ショートカットが無効化された
    case shortcutDisabled
}

// MARK: - ShortcutConfiguration（ショートカット設定）

/// グローバルショートカットキーの設定を管理するエンティティ。
/// fn（Globe）キー固定でプッシュトゥトーク方式の音声入力を制御する。
///
/// ## ビジネスルール
/// - ショートカットキーは fn（Globe）キー固定（ユーザーによるキー変更は不要）
/// - fn キーは長押し方式で動作する（押し続けている間 = 録音、離す = 停止）
/// - どのアプリケーションがフォーカスされていても、グローバルに動作する
@MainActor
final class ShortcutConfiguration: ObservableObject {

    // MARK: - 属性

    /// ショートカットが有効かどうか
    @Published private(set) var isEnabled: Bool

    // MARK: - ドメインイベントパブリッシャー

    let eventPublisher = PassthroughSubject<ShortcutEvent, Never>()

    // MARK: - 初期化

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    // MARK: - 振る舞い

    /// ショートカットを有効にする
    /// - Postcondition: isEnabled が true に設定される
    func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        eventPublisher.send(.shortcutEnabled)
    }

    /// ショートカットを無効にする
    /// - Postcondition: isEnabled が false に設定される
    func disable() {
        guard isEnabled else { return }
        isEnabled = false
        eventPublisher.send(.shortcutDisabled)
    }

    /// ショートカットの有効/無効を切り替える
    func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }
}
