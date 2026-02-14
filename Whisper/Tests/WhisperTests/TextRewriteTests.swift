import Testing
@testable import Whisper

@Suite("TextRewrite Tests")
struct TextRewriteTests {

    @Test("初期状態は Pending")
    @MainActor
    func initialStatusIsPending() {
        let rewrite = TextRewrite(rawText: "こんにちは", sourceRecognitionResultId: .init())
        #expect(rewrite.status == .pending)
        #expect(rewrite.rewrittenText == nil)
        #expect(rewrite.rawText == "こんにちは")
    }

    @Test("startRewrite で Pending → Processing に遷移する")
    @MainActor
    func startRewriteTransitions() {
        let rewrite = TextRewrite(rawText: "テスト", sourceRecognitionResultId: .init())
        rewrite.startRewrite()
        #expect(rewrite.status == .processing)
    }

    @Test("completeRewrite で Processing → Completed に遷移する")
    @MainActor
    func completeRewriteTransitions() {
        let rewrite = TextRewrite(rawText: "えーとテスト", sourceRecognitionResultId: .init())
        rewrite.startRewrite()
        rewrite.completeRewrite(rewrittenText: "テスト")
        #expect(rewrite.status == .completed)
        #expect(rewrite.rewrittenText == "テスト")
    }

    @Test("failRewrite で Processing → Failed に遷移する")
    @MainActor
    func failRewriteTransitions() {
        let rewrite = TextRewrite(rawText: "テスト", sourceRecognitionResultId: .init())
        rewrite.startRewrite()
        let error = NSError(domain: "test", code: -1)
        rewrite.failRewrite(error: error)
        #expect(rewrite.status == .failed)
    }

    @Test("getFinalText は Completed 時に rewrittenText を返す")
    @MainActor
    func getFinalTextReturnsRewritten() {
        let rewrite = TextRewrite(rawText: "えーとテスト", sourceRecognitionResultId: .init())
        rewrite.startRewrite()
        rewrite.completeRewrite(rewrittenText: "テスト")
        #expect(rewrite.getFinalText() == "テスト")
    }

    @Test("getFinalText は Failed 時に rawText をフォールバックで返す")
    @MainActor
    func getFinalTextFallsBackToRawText() {
        let rewrite = TextRewrite(rawText: "えーとテスト", sourceRecognitionResultId: .init())
        rewrite.startRewrite()
        rewrite.failRewrite(error: NSError(domain: "test", code: -1))
        #expect(rewrite.getFinalText() == "えーとテスト")
    }

    @Test("Pending 以外の状態で startRewrite は無視される")
    @MainActor
    func startRewriteIgnoredWhenNotPending() {
        let rewrite = TextRewrite(rawText: "テスト", sourceRecognitionResultId: .init())
        rewrite.startRewrite()
        rewrite.startRewrite() // 2回目は無視
        #expect(rewrite.status == .processing)
    }

    @Test("getRawText は常に元のテキストを返す")
    @MainActor
    func getRawTextAlwaysReturnsOriginal() {
        let rewrite = TextRewrite(rawText: "えーとテスト", sourceRecognitionResultId: .init())
        rewrite.startRewrite()
        rewrite.completeRewrite(rewrittenText: "テスト")
        #expect(rewrite.getRawText() == "えーとテスト")
    }
}
