import Testing
@testable import Whisper

@Suite("TextOutput Tests")
struct TextOutputTests {

    @Test("初期状態は Pending")
    @MainActor
    func initialStatusIsPending() {
        let output = TextOutput(text: "テスト")
        #expect(output.status == .pending)
        #expect(output.text == "テスト")
        #expect(output.outputMethod == .activeField)
    }

    @Test("デフォルトの出力方法は ActiveField")
    @MainActor
    func defaultOutputMethodIsActiveField() {
        let output = TextOutput(text: "テスト")
        #expect(output.outputMethod == .activeField)
    }

    @Test("出力方法を変更できる")
    @MainActor
    func setOutputMethod() {
        let output = TextOutput(text: "テスト")
        output.setOutputMethod(.clipboard)
        #expect(output.outputMethod == .clipboard)

        output.setOutputMethod(.both)
        #expect(output.outputMethod == .both)
    }

    @Test("outputToActiveField で Completed に遷移する")
    @MainActor
    func outputToActiveFieldCompletes() {
        let output = TextOutput(text: "テスト")
        output.outputToActiveField(activeWindowInfo: nil)
        #expect(output.status == .completed)
    }

    @Test("copyToClipboard で Completed に遷移する")
    @MainActor
    func copyToClipboardCompletes() {
        let output = TextOutput(text: "テスト")
        output.copyToClipboard()
        #expect(output.status == .completed)
    }

    @Test("failOutput で Failed に遷移する")
    @MainActor
    func failOutputTransitions() {
        let output = TextOutput(text: "テスト")
        let error = NSError(domain: "test", code: -1)
        output.failOutput(error: error)
        #expect(output.status == .failed)
    }

    @Test("OutputMethod.displayName が正しい")
    func outputMethodDisplayNames() {
        #expect(OutputMethod.activeField.displayName == "アクティブフィールド")
        #expect(OutputMethod.clipboard.displayName == "クリップボード")
        #expect(OutputMethod.both.displayName == "両方")
    }
}
