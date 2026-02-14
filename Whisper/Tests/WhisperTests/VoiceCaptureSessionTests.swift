import Testing
@testable import Whisper

// MARK: - CaptureStatus Tests

@Suite("VoiceCaptureSession Tests")
struct VoiceCaptureSessionTests {

    @Test("初期状態は Idle")
    @MainActor
    func initialStatusIsIdle() {
        let session = VoiceCaptureSession()
        #expect(session.status == .idle)
        #expect(session.startedAt == nil)
        #expect(session.stoppedAt == nil)
    }

    @Test("startCapture で Idle → Recording に遷移する")
    @MainActor
    func startCaptureTransitionsToRecording() {
        let session = VoiceCaptureSession()
        session.startCapture()
        #expect(session.status == .recording)
        #expect(session.startedAt != nil)
    }

    @Test("stopCapture で Recording → Processing に遷移する")
    @MainActor
    func stopCaptureTransitionsToProcessing() {
        let session = VoiceCaptureSession()
        session.startCapture()
        session.stopCapture()
        #expect(session.status == .processing)
        #expect(session.stoppedAt != nil)
    }

    @Test("complete で Processing → Idle に遷移する")
    @MainActor
    func completeTransitionsToIdle() {
        let session = VoiceCaptureSession()
        session.startCapture()
        session.stopCapture()
        session.complete()
        #expect(session.status == .idle)
    }

    @Test("Idle 以外の状態で startCapture は無視される")
    @MainActor
    func startCaptureIgnoredWhenNotIdle() {
        let session = VoiceCaptureSession()
        session.startCapture()
        // Recording 状態で再度 startCapture
        session.startCapture()
        #expect(session.status == .recording)
    }

    @Test("Recording 以外の状態で stopCapture は無視される")
    @MainActor
    func stopCaptureIgnoredWhenNotRecording() {
        let session = VoiceCaptureSession()
        // Idle 状態で stopCapture
        session.stopCapture()
        #expect(session.status == .idle)
    }

    @Test("Processing 以外の状態で complete は無視される")
    @MainActor
    func completeIgnoredWhenNotProcessing() {
        let session = VoiceCaptureSession()
        // Idle 状態で complete
        session.complete()
        #expect(session.status == .idle)

        session.startCapture()
        // Recording 状態で complete
        session.complete()
        #expect(session.status == .recording)
    }

    @Test("完全な状態遷移サイクル: Idle → Recording → Processing → Idle")
    @MainActor
    func fullCycleTransition() {
        let session = VoiceCaptureSession()

        #expect(session.status == .idle)
        session.startCapture()
        #expect(session.status == .recording)
        session.stopCapture()
        #expect(session.status == .processing)
        session.complete()
        #expect(session.status == .idle)
    }
}
