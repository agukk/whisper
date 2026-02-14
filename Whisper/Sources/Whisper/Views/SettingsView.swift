import SwiftUI

/// 設定画面ビュー
struct SettingsView: View {

    @ObservedObject var shortcutConfig: ShortcutConfiguration
    @ObservedObject var languageConfig: LanguageConfiguration

    var body: some View {
        Form {
            // MARK: - ショートカット設定
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

            // MARK: - 言語設定
            Section("認識言語") {
                Toggle("日本語", isOn: Binding(
                    get: { languageConfig.isLanguageEnabled(.japanese) },
                    set: { newValue in
                        if newValue {
                            languageConfig.addLanguage(.japanese)
                        } else {
                            languageConfig.removeLanguage(.japanese)
                        }
                    }
                ))

                Toggle("English", isOn: Binding(
                    get: { languageConfig.isLanguageEnabled(.english) },
                    set: { newValue in
                        if newValue {
                            languageConfig.addLanguage(.english)
                        } else {
                            languageConfig.removeLanguage(.english)
                        }
                    }
                ))

                if languageConfig.isMultiLanguageEnabled() {
                    Text("日英混合認識モードで動作します。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("少なくとも1つの言語を有効にしてください。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 280)
        .navigationTitle("Whisper 設定")
    }
}
