import Testing
@testable import Whisper

@Suite("SpeechRecognitionSession Tests")
struct SpeechRecognitionSessionTests {

    @Test("初期状態は Idle")
    @MainActor
    func initialStatusIsIdle() {
        let config = LanguageConfiguration()
        let session = SpeechRecognitionSession(languageConfiguration: config)
        #expect(session.status == .idle)
        #expect(session.result == nil)
    }

    @Test("startRecognition で Idle → Recognizing に遷移する")
    @MainActor
    func startRecognitionTransitions() {
        let config = LanguageConfiguration()
        let session = SpeechRecognitionSession(languageConfiguration: config)
        session.startRecognition()
        #expect(session.status == .recognizing)
    }

    @Test("stopRecognition で Recognizing → Finalizing に遷移する")
    @MainActor
    func stopRecognitionTransitions() {
        let config = LanguageConfiguration()
        let session = SpeechRecognitionSession(languageConfiguration: config)
        session.startRecognition()
        session.stopRecognition()
        #expect(session.status == .finalizing)
    }

    @Test("completeRecognition で Finalizing → Completed に遷移する")
    @MainActor
    func completeRecognitionTransitions() {
        let config = LanguageConfiguration()
        let session = SpeechRecognitionSession(languageConfiguration: config)
        session.startRecognition()
        session.stopRecognition()

        let result = RecognitionResult()
        result.addSegment(RecognitionSegment(text: "テスト", language: .japanese, order: 0))
        session.completeRecognition(with: result)

        #expect(session.status == .completed)
        #expect(session.result != nil)
        #expect(session.result?.getFullText() == "テスト")
    }

    @Test("failRecognition で Recognizing → Failed に遷移する")
    @MainActor
    func failFromRecognizing() {
        let config = LanguageConfiguration()
        let session = SpeechRecognitionSession(languageConfiguration: config)
        session.startRecognition()

        let error = NSError(domain: "test", code: -1)
        session.failRecognition(error: error)
        #expect(session.status == .failed)
    }

    @Test("failRecognition で Finalizing → Failed に遷移する")
    @MainActor
    func failFromFinalizing() {
        let config = LanguageConfiguration()
        let session = SpeechRecognitionSession(languageConfiguration: config)
        session.startRecognition()
        session.stopRecognition()

        let error = NSError(domain: "test", code: -1)
        session.failRecognition(error: error)
        #expect(session.status == .failed)
    }

    @Test("Idle 状態で stopRecognition は無視される")
    @MainActor
    func stopIgnoredWhenIdle() {
        let config = LanguageConfiguration()
        let session = SpeechRecognitionSession(languageConfiguration: config)
        session.stopRecognition()
        #expect(session.status == .idle)
    }

    @Test("reset でセッションが再利用可能になる")
    @MainActor
    func resetSession() {
        let config = LanguageConfiguration()
        let session = SpeechRecognitionSession(languageConfiguration: config)
        session.startRecognition()
        session.stopRecognition()

        let result = RecognitionResult()
        session.completeRecognition(with: result)
        #expect(session.status == .completed)

        session.reset()
        #expect(session.status == .idle)
        #expect(session.result == nil)
    }

    @Test("完全な状態遷移サイクル: Idle → Recognizing → Finalizing → Completed")
    @MainActor
    func fullCycleTransition() {
        let config = LanguageConfiguration()
        let session = SpeechRecognitionSession(languageConfiguration: config)

        #expect(session.status == .idle)
        session.startRecognition()
        #expect(session.status == .recognizing)
        session.stopRecognition()
        #expect(session.status == .finalizing)

        let result = RecognitionResult()
        result.addSegment(RecognitionSegment(text: "Hello", language: .english, order: 0))
        session.completeRecognition(with: result)
        #expect(session.status == .completed)
        #expect(session.result?.getFullText() == "Hello")
    }
}
