import Foundation
import GoogleGenerativeAI

// MARK: - GeminiRewriteService

/// Gemini Flash API を使用して音声認識テキストをリライトするサービス
@MainActor
final class GeminiRewriteService: ObservableObject {

    // MARK: - リライト用プロンプトテンプレート

    private static let rewritePrompt = """
    以下の音声認識結果を自然な文章に修正してください。

    ルール:
    - フィラーワード（えーと、あのー、um、uh、あー、えー）を除去してください
    - 文法的に正しい文章に修正してください
    - 句読点を適切に挿入してください
    - 元の意味は必ず保持してください
    - 余計な説明や注釈は付けず、修正後のテキストのみを返してください
    - 日本語と英語が混在している場合は、それぞれの言語の文法ルールに従ってください

    音声認識結果:
    """

    // MARK: - 属性

    private var model: GenerativeModel?

    // MARK: - 初期化

    /// Keychain から API キーを読み込んでモデルを初期化する
    func configure() {
        guard let apiKey = KeychainService.load(key: .geminiAPIKey) else {
            print("[GeminiRewriteService] API key not found in Keychain")
            return
        }

        model = GenerativeModel(
            name: "gemini-2.0-flash",
            apiKey: apiKey
        )
        print("[GeminiRewriteService] Configured with Gemini Flash model")
    }

    /// API キーが設定済みかどうか
    var isConfigured: Bool {
        return model != nil
    }

    // MARK: - リライト実行

    /// テキストをリライトする
    /// - Parameter rawText: リライト対象のテキスト
    /// - Returns: リライト後のテキスト
    /// - Throws: API 呼び出しエラー
    func rewrite(_ rawText: String) async throws -> String {
        guard let model = model else {
            throw GeminiRewriteError.notConfigured
        }

        let prompt = Self.rewritePrompt + rawText

        let response = try await model.generateContent(prompt)

        guard let rewrittenText = response.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rewrittenText.isEmpty else {
            throw GeminiRewriteError.emptyResponse
        }

        print("[GeminiRewriteService] Rewrite completed: \(rawText) → \(rewrittenText)")
        return rewrittenText
    }
}

// MARK: - エラー

enum GeminiRewriteError: LocalizedError {
    case notConfigured
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Gemini API キーが設定されていません。設定画面で API キーを入力してください。"
        case .emptyResponse:
            return "Gemini API から空のレスポンスが返されました。"
        }
    }
}
