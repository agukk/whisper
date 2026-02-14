import SwiftUI
import Combine

/// Whisper — macOS メニューバー常駐の音声入力アプリケーション
@main
struct WhisperApp: App {

    // MARK: - ドメインモデル

    @StateObject private var captureSession = VoiceCaptureSession()
    @StateObject private var shortcutConfig = ShortcutConfiguration()
    @StateObject private var appLifecycle = ApplicationLifecycle()

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
            SettingsView(shortcutConfig: shortcutConfig)
        }
    }

    // MARK: - 初期化

    init() {
        // サービスの初期化は onAppear で行う
    }
}

// MARK: - AppDelegate（サービス接続用）

/// アプリケーション起動時にサービスを初期化しドメインモデルと接続する
@MainActor
final class AppCoordinator: ObservableObject {

    let captureSession: VoiceCaptureSession
    let shortcutConfig: ShortcutConfiguration
    let appLifecycle: ApplicationLifecycle
    let audioCaptureService: AudioCaptureService
    let hotkeyService: GlobalHotkeyService
    private var cancellables = Set<AnyCancellable>()

    init(
        captureSession: VoiceCaptureSession,
        shortcutConfig: ShortcutConfiguration,
        appLifecycle: ApplicationLifecycle,
        audioCaptureService: AudioCaptureService,
        hotkeyService: GlobalHotkeyService
    ) {
        self.captureSession = captureSession
        self.shortcutConfig = shortcutConfig
        self.appLifecycle = appLifecycle
        self.audioCaptureService = audioCaptureService
        self.hotkeyService = hotkeyService

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
                    // スタブ: 即座に完了
                    self.captureSession.complete()
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
    }
}
