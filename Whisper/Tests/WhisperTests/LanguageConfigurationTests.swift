import Testing
@testable import Whisper

@Suite("LanguageConfiguration Tests")
struct LanguageConfigurationTests {

    @Test("デフォルトでは日本語・英語の両方が有効")
    @MainActor
    func defaultBothLanguagesEnabled() {
        let config = LanguageConfiguration()
        #expect(config.isLanguageEnabled(.japanese))
        #expect(config.isLanguageEnabled(.english))
        #expect(config.isMultiLanguageEnabled())
    }

    @Test("言語を削除できる")
    @MainActor
    func removeLanguage() {
        let config = LanguageConfiguration()
        let removed = config.removeLanguage(.english)
        #expect(removed == true)
        #expect(config.isLanguageEnabled(.english) == false)
        #expect(config.isLanguageEnabled(.japanese) == true)
    }

    @Test("最後の1言語は削除できない")
    @MainActor
    func cannotRemoveLastLanguage() {
        let config = LanguageConfiguration(enabledLanguages: [.japanese])
        let removed = config.removeLanguage(.japanese)
        #expect(removed == false)
        #expect(config.isLanguageEnabled(.japanese) == true)
    }

    @Test("言語を追加できる")
    @MainActor
    func addLanguage() {
        let config = LanguageConfiguration(enabledLanguages: [.japanese])
        let added = config.addLanguage(.english)
        #expect(added == true)
        #expect(config.isLanguageEnabled(.english) == true)
        #expect(config.isMultiLanguageEnabled() == true)
    }

    @Test("重複追加は失敗する")
    @MainActor
    func duplicateAddFails() {
        let config = LanguageConfiguration()
        let added = config.addLanguage(.japanese) // 既に含まれている
        #expect(added == false)
    }

    @Test("isMultiLanguageEnabled が正しく判定される")
    @MainActor
    func multiLanguageEnabled() {
        let singleLang = LanguageConfiguration(enabledLanguages: [.japanese])
        #expect(singleLang.isMultiLanguageEnabled() == false)

        let multiLang = LanguageConfiguration(enabledLanguages: [.japanese, .english])
        #expect(multiLang.isMultiLanguageEnabled() == true)
    }

    @Test("getEnabledLanguages が正しいセットを返す")
    @MainActor
    func getEnabledLanguages() {
        let config = LanguageConfiguration(enabledLanguages: [.japanese])
        let languages = config.getEnabledLanguages()
        #expect(languages == Set([Language.japanese]))
    }
}
