import SwiftUI

/// メニューバーのポップオーバービュー
struct MenuBarView: View {

    @ObservedObject var captureSession: VoiceCaptureSession
    @ObservedObject var shortcutConfig: ShortcutConfiguration
    @ObservedObject var appLifecycle: ApplicationLifecycle

    var body: some View {
        VStack(spacing: 12) {
            // 録音状態表示
            statusSection

            Divider()

            // プッシュトゥトークボタン
            pushToTalkButton

            Divider()

            // メニュー項目
            menuItems
        }
        .padding(8)
        .frame(width: 220)
    }

    // MARK: - Sections

    /// 現在の録音状態表示
    private var statusSection: some View {
        HStack {
            Image(systemName: appLifecycle.menuBarIconName)
                .foregroundColor(statusColor)
                .font(.title2)

            Text(statusText)
                .font(.headline)

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    /// プッシュトゥトークボタン
    private var pushToTalkButton: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: captureSession.status == .recording ? "mic.fill" : "mic.slash.fill")
                Text(captureSession.status == .recording ? "録音中..." : "長押しで録音")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(captureSession.status == .recording ? .red : .accentColor)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if captureSession.status == .idle {
                        captureSession.startCapture()
                    }
                }
                .onEnded { _ in
                    if captureSession.status == .recording {
                        captureSession.stopCapture()
                    }
                }
        )
    }

    /// メニュー項目（設定、終了）
    private var menuItems: some View {
        VStack(spacing: 4) {
            // ショートカット状態
            HStack {
                Image(systemName: "globe")
                Text("fn キー")
                Spacer()
                Text(shortcutConfig.isEnabled ? "有効" : "無効")
                    .foregroundColor(shortcutConfig.isEnabled ? .green : .secondary)
                    .font(.caption)
            }
            .padding(.horizontal, 4)

            Divider()

            // 設定ボタン
            SettingsLink {
                HStack {
                    Image(systemName: "gear")
                    Text("設定...")
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }

            // 終了ボタン
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("Whisper を終了")
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private var statusText: String {
        switch captureSession.status {
        case .idle:
            return "待機中"
        case .recording:
            return "録音中"
        case .processing:
            return "処理中..."
        }
    }

    private var statusColor: Color {
        switch captureSession.status {
        case .idle:
            return .secondary
        case .recording:
            return .red
        case .processing:
            return .orange
        }
    }
}
