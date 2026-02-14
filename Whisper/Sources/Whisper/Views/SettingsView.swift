import SwiftUI

/// 設定画面ビュー
struct SettingsView: View {

    @ObservedObject var shortcutConfig: ShortcutConfiguration

    var body: some View {
        Form {
            Section("ショートカット") {
                Toggle("fn（Globe）キーで音声入力を開始", isOn: Binding(
                    get: { shortcutConfig.isEnabled },
                    set: { newValue in
                        if newValue {
                            shortcutConfig.enable()
                        } else {
                            shortcutConfig.disable()
                        }
                    }
                ))

                Text("fn キーを長押しすると録音を開始し、離すと停止します。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 150)
        .navigationTitle("Whisper 設定")
    }
}
