import Testing
@testable import Whisper

@Suite("ShortcutConfiguration Tests")
struct ShortcutConfigurationTests {

    @Test("初期状態は有効")
    @MainActor
    func initialStateIsEnabled() {
        let config = ShortcutConfiguration()
        #expect(config.isEnabled == true)
    }

    @Test("disable で無効化される")
    @MainActor
    func disableWorks() {
        let config = ShortcutConfiguration()
        config.disable()
        #expect(config.isEnabled == false)
    }

    @Test("enable で有効化される")
    @MainActor
    func enableWorks() {
        let config = ShortcutConfiguration(isEnabled: false)
        config.enable()
        #expect(config.isEnabled == true)
    }

    @Test("既に有効な状態で enable は無視される")
    @MainActor
    func enableWhenAlreadyEnabled() {
        let config = ShortcutConfiguration(isEnabled: true)
        config.enable()
        #expect(config.isEnabled == true)
    }

    @Test("既に無効な状態で disable は無視される")
    @MainActor
    func disableWhenAlreadyDisabled() {
        let config = ShortcutConfiguration(isEnabled: false)
        config.disable()
        #expect(config.isEnabled == false)
    }

    @Test("toggle で有効/無効が切り替わる")
    @MainActor
    func toggleWorks() {
        let config = ShortcutConfiguration(isEnabled: true)
        config.toggle()
        #expect(config.isEnabled == false)
        config.toggle()
        #expect(config.isEnabled == true)
    }
}
