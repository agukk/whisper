import SwiftUI
import Combine

/// Whisper — macOS メニューバー常駐の音声入力アプリケーション
@main
struct WhisperApp: App {

    // MARK: - ドメインモデル

    @StateObject private var captureSession = VoiceCaptureSession()
    @StateObject private var shortcutConfig = ShortcutConfiguration()
    @StateObject private var appLifecycle = ApplicationLifecycle()
    @StateObject private var languageConfig = LanguageConfiguration()

    // MARK: - サービス

    @StateObject private var audioCaptureService = AudioCaptureService()
    @StateObject private var hotkeyService = GlobalHotkeyService()
    @StateObject private var activeWindowService = ActiveWindowService()

    // MARK: - Body

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                captureSession: captureSession,
                shortcutConfig: shortcutConfig,
                appLifecycle: appLifecycle
            )
        } label: {
            Image(systemName: appLifecycle.menuBarIconName)
        }

        Settings {
            SettingsView(
                shortcutConfig: shortcutConfig,
                languageConfig: languageConfig
            )
        }
    }

    // MARK: - 初期化

    init() {
        // サービスの初期化は onAppear で行う
    }
}

// MARK: - AppCoordinator（サービス接続用）

/// アプリケーション起動時にサービスを初期化しドメインモデルと接続する
@MainActor
final class AppCoordinator: ObservableObject {

    let captureSession: VoiceCaptureSession
    let shortcutConfig: ShortcutConfiguration
    let appLifecycle: ApplicationLifecycle
    let languageConfig: LanguageConfiguration
    let audioCaptureService: AudioCaptureService
    let hotkeyService: GlobalHotkeyService
    let activeWindowService: ActiveWindowService
    let speechRecognitionService: SpeechRecognitionService
    let geminiRewriteService: GeminiRewriteService
    let textInsertionService: TextInsertionService

    /// 現在の出力方法設定
    @Published var outputMethod: OutputMethod = .activeField

    private var cancellables = Set<AnyCancellable>()

    init(
        captureSession: VoiceCaptureSession,
        shortcutConfig: ShortcutConfiguration,
        appLifecycle: ApplicationLifecycle,
        languageConfig: LanguageConfiguration,
        audioCaptureService: AudioCaptureService,
        hotkeyService: GlobalHotkeyService,
        activeWindowService: ActiveWindowService
    ) {
        self.captureSession = captureSession
        self.shortcutConfig = shortcutConfig
        self.appLifecycle = appLifecycle
        self.languageConfig = languageConfig
        self.audioCaptureService = audioCaptureService
        self.hotkeyService = hotkeyService
        self.activeWindowService = activeWindowService
        self.speechRecognitionService = SpeechRecognitionService(languageConfiguration: languageConfig)
        self.geminiRewriteService = GeminiRewriteService()
        self.textInsertionService = TextInsertionService()

        setupBindings()
    }

    private func setupBindings() {
        // fn キーの押下/解放 → VoiceCaptureSession の状態遷移
        hotkeyService.onKeyDown = { [weak self] in
            guard let self, self.shortcutConfig.isEnabled else { return }
            self.captureSession.startCapture()
        }
        hotkeyService.onKeyUp = { [weak self] in
            guard let self else { return }
            self.captureSession.stopCapture()
        }

        // AudioCaptureService の出力先を SpeechRecognitionService に接続
        audioCaptureService.streamOutput = speechRecognitionService

        // SpeechRecognitionService のコールバック設定
        // Unit 2 → Unit 3: 認識完了 → リライト → テキスト出力
        speechRecognitionService.onRecognitionCompleted = { [weak self] result in
            guard let self else { return }
            let fullText = result.getFullText()
            print("[AppCoordinator] Recognition completed: \(fullText)")

            // Unit 3: TextRewrite → TextOutput パイプライン
            Task {
                await self.processRewriteAndOutput(
                    rawText: fullText,
                    recognitionResultId: result.resultId
                )
            }
        }
        speechRecognitionService.onRecognitionFailed = { [weak self] error in
            guard let self else { return }
            print("[AppCoordinator] Recognition failed: \(error.localizedDescription)")
            self.captureSession.complete()
        }

        // VoiceCaptureSession のイベント → サービス連携
        captureSession.eventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .captureStarted:
                    self.audioCaptureService.startCapture()
                    self.appLifecycle.updateIconState(captureStatus: .recording)
                case .captureStopped:
                    self.audioCaptureService.stopCapture()
                    self.appLifecycle.updateIconState(captureStatus: .processing)
                case .captureCompleted:
                    self.appLifecycle.updateIconState(captureStatus: .idle)
                }
            }
            .store(in: &cancellables)

        // ショートカット設定の変更 → GlobalHotkeyService の制御
        shortcutConfig.eventPublisher
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .shortcutEnabled:
                    self.hotkeyService.startMonitoring()
                case .shortcutDisabled:
                    self.hotkeyService.stopMonitoring()
                }
            }
            .store(in: &cancellables)

        // 初期状態: ショートカットが有効なら監視開始
        if shortcutConfig.isEnabled {
            hotkeyService.startMonitoring()
        }

        // Gemini API の初期化
        geminiRewriteService.configure()

        // アクセシビリティ権限の確認
        _ = TextInsertionService.checkAccessibilityPermission()
    }

    // MARK: - Unit 3 パイプライン

    /// 認識結果テキストをリライトし、出力する
    private func processRewriteAndOutput(rawText: String, recognitionResultId: UUID) async {
        let rewrite = TextRewrite(
            rawText: rawText,
            sourceRecognitionResultId: recognitionResultId
        )

        // リライト開始
        rewrite.startRewrite()

        // Gemini API でリライト
        if geminiRewriteService.isConfigured {
            do {
                let rewrittenText = try await geminiRewriteService.rewrite(rawText)
                rewrite.completeRewrite(rewrittenText: rewrittenText)
            } catch {
                print("[AppCoordinator] Rewrite failed: \(error.localizedDescription)")
                rewrite.failRewrite(error: error)
            }
        } else {
            // API キー未設定の場合はリライトスキップ（rawText をそのまま使用）
            print("[AppCoordinator] Gemini not configured, using raw text")
            rewrite.failRewrite(error: GeminiRewriteError.notConfigured)
        }

        // 最終テキストを取得
        let finalText = rewrite.getFinalText()

        // TextOutput で出力
        let output = TextOutput(text: finalText, outputMethod: outputMethod)
        let activeWindowInfo = activeWindowService.getActiveWindowInfo()

        switch outputMethod {
        case .activeField:
            textInsertionService.insertText(finalText)
            output.outputToActiveField(activeWindowInfo: activeWindowInfo)
        case .clipboard:
            textInsertionService.copyToClipboard(finalText)
            output.copyToClipboard()
        case .both:
            textInsertionService.insertText(finalText)
            textInsertionService.copyToClipboard(finalText)
            output.executeOutput(activeWindowInfo: activeWindowInfo)
        }

        print("[AppCoordinator] Text output completed: \(finalText)")

        // VoiceCaptureSession を完了状態に遷移
        captureSession.complete()
    }
}
