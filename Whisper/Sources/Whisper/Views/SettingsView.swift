import SwiftUI

/// 設定画面ビュー
struct SettingsView: View {

    @ObservedObject var shortcutConfig: ShortcutConfiguration
    @ObservedObject var languageConfig: LanguageConfiguration

    // MARK: - API キー状態
    @State private var apiKeyInput: String = ""
    @State private var isApiKeySaved: Bool = false
    @State private var showApiKeyAlert: Bool = false

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

            // MARK: - Gemini API 設定
            Section("Gemini API") {
                SecureField("API キー", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("保存") {
                        if !apiKeyInput.isEmpty {
                            KeychainService.save(key: .geminiAPIKey, value: apiKeyInput)
                            isApiKeySaved = true
                            apiKeyInput = ""
                            showApiKeyAlert = true
                        }
                    }
                    .disabled(apiKeyInput.isEmpty)

                    if KeychainService.exists(key: .geminiAPIKey) {
                        Button("削除", role: .destructive) {
                            KeychainService.delete(key: .geminiAPIKey)
                            isApiKeySaved = false
                        }
                    }

                    Spacer()

                    if KeychainService.exists(key: .geminiAPIKey) {
                        Label("設定済み", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Label("未設定", systemImage: "xmark.circle")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }

                Text("Gemini API キーは Keychain に安全に保存されます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // MARK: - 出力設定
            Section("出力方法") {
                Picker("出力先", selection: .constant(OutputMethod.activeField)) {
                    ForEach(OutputMethod.allCases, id: \.self) { method in
                        Text(method.displayName).tag(method)
                    }
                }

                Text("アクティブフィールド: カーソル位置にテキストを直接入力\nクリップボード: テキストをクリップボードにコピー\n両方: 直接入力 + クリップボードコピー")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 520)
        .navigationTitle("Whisper 設定")
        .alert("API キーを保存しました", isPresented: $showApiKeyAlert) {
            Button("OK") {}
        }
    }
}
