import Foundation
import Combine

// MARK: - ドメインイベント

/// LanguageConfiguration が発行するドメインイベント
enum LanguageConfigEvent {
    /// 言語が追加された
    case languageAdded(Language)
    /// 言語が削除された
    case languageRemoved(Language)
}

// MARK: - LanguageConfiguration（言語設定）

/// 音声認識の対象言語を管理するエンティティ。
/// 現時点では日本語と英語の2言語に限定し、ユーザーが複数言語を同時に選択して認識対象とすることができる。
///
/// ## ビジネスルール
/// - サポート対象言語は日本語と英語の2言語のみ
/// - 少なくとも1つの言語が常に有効でなければならない（全言語の削除は不可）
/// - 同一言語の重複追加は不可
/// - 複数言語が選択されている場合、日英混合認識モードで動作する
@MainActor
final class LanguageConfiguration: ObservableObject {

    // MARK: - 属性

    /// 現在有効な認識対象言語のセット
    @Published private(set) var enabledLanguages: Set<Language>

    // MARK: - ドメインイベントパブリッシャー

    let eventPublisher = PassthroughSubject<LanguageConfigEvent, Never>()

    // MARK: - 初期化

    /// デフォルトでは日本語・英語の両方が有効
    init(enabledLanguages: Set<Language> = [.japanese, .english]) {
        self.enabledLanguages = enabledLanguages
    }

    // MARK: - 振る舞い

    /// 認識対象に言語を追加する
    /// - Parameter language: 追加する言語
    /// - Returns: 追加に成功した場合 true（既に含まれている場合は false）
    @discardableResult
    func addLanguage(_ language: Language) -> Bool {
        guard !enabledLanguages.contains(language) else { return false }
        enabledLanguages.insert(language)
        eventPublisher.send(.languageAdded(language))
        return true
    }

    /// 認識対象から言語を削除する
    /// - Parameter language: 削除する言語
    /// - Returns: 削除に成功した場合 true（最後の1言語の場合は削除不可で false）
    @discardableResult
    func removeLanguage(_ language: Language) -> Bool {
        guard enabledLanguages.contains(language) else { return false }
        guard enabledLanguages.count > 1 else { return false }
        enabledLanguages.remove(language)
        eventPublisher.send(.languageRemoved(language))
        return true
    }

    /// 現在有効な言語のリストを返す
    func getEnabledLanguages() -> Set<Language> {
        return enabledLanguages
    }

    /// 複数言語が有効かどうかを判定する
    func isMultiLanguageEnabled() -> Bool {
        return enabledLanguages.count >= 2
    }

    /// 指定言語が有効かどうかを判定する
    func isLanguageEnabled(_ language: Language) -> Bool {
        return enabledLanguages.contains(language)
    }
}
