import Foundation
import Combine

// MARK: - OutputMethod（出力方法）

/// テキストの出力先を表す値オブジェクト
enum OutputMethod: String, CaseIterable, Equatable {
    /// アクティブなテキストフィールドへの直接入力（デフォルト）
    case activeField = "ActiveField"
    /// クリップボードへのコピーのみ
    case clipboard = "Clipboard"
    /// アクティブフィールド入力とクリップボードコピーの両方
    case both = "Both"

    /// 表示用の名前
    var displayName: String {
        switch self {
        case .activeField: return "アクティブフィールド"
        case .clipboard: return "クリップボード"
        case .both: return "両方"
        }
    }
}

// MARK: - OutputStatus（出力状態）

/// テキスト出力処理の状態を表す値オブジェクト
enum OutputStatus: Equatable {
    /// 出力待ち
    case pending
    /// 出力処理中
    case outputting
    /// 出力完了
    case completed
    /// 出力失敗
    case failed
}

// MARK: - ドメインイベント

/// TextOutput が発行するドメインイベント
enum TextOutputEvent {
    /// テキスト出力が完了した
    case textOutputCompleted(outputId: UUID, text: String, outputMethod: OutputMethod)
    /// クリップボードにコピーされた
    case textCopiedToClipboard(outputId: UUID, text: String)
    /// テキスト出力が失敗した
    case textOutputFailed(outputId: UUID, error: Error)
}

// MARK: - TextOutput（テキスト出力）

/// リライト処理後のテキストを外部アプリケーションに出力するエンティティ。
///
/// ## ビジネスルール
/// - デフォルトの出力方法は ActiveField
/// - クリップボードコピーは独立した追加アクションとして常に利用可能
/// - アクティブフィールドへの入力は既存テキストへの追記
/// - コピー成功時には UI フィードバックが表示される
@MainActor
final class TextOutput: ObservableObject {

    // MARK: - 属性

    let outputId: UUID
    let text: String
    @Published private(set) var outputMethod: OutputMethod
    @Published private(set) var status: OutputStatus

    // MARK: - ドメインイベントパブリッシャー

    let eventPublisher = PassthroughSubject<TextOutputEvent, Never>()

    // MARK: - 初期化

    init(
        outputId: UUID = UUID(),
        text: String,
        outputMethod: OutputMethod = .activeField
    ) {
        self.outputId = outputId
        self.text = text
        self.outputMethod = outputMethod
        self.status = .pending
    }

    // MARK: - 振る舞い

    /// outputMethod の設定に基づいて適切な出力処理を実行する
    /// - Parameter activeWindowInfo: アクティブウィンドウの情報（ActiveField 出力時に使用）
    func executeOutput(activeWindowInfo: ActiveWindowInfo?) {
        status = .outputting

        switch outputMethod {
        case .activeField:
            outputToActiveField(activeWindowInfo: activeWindowInfo)
        case .clipboard:
            copyToClipboard()
        case .both:
            outputToActiveField(activeWindowInfo: activeWindowInfo)
            copyToClipboard()
        }
    }

    /// アクティブなテキストフィールドにテキストを入力する
    /// - Parameter activeWindowInfo: アクティブウィンドウの情報
    func outputToActiveField(activeWindowInfo: ActiveWindowInfo?) {
        // 実際の挿入は TextInsertionService が行う
        // ここではドメインイベントを発行するのみ
        status = .completed
        eventPublisher.send(.textOutputCompleted(
            outputId: outputId,
            text: text,
            outputMethod: .activeField
        ))
    }

    /// テキストをクリップボードにコピーする
    func copyToClipboard() {
        // 実際のコピーは TextInsertionService が行う
        // ここではドメインイベントを発行するのみ
        status = .completed
        eventPublisher.send(.textCopiedToClipboard(outputId: outputId, text: text))
    }

    /// 出力方法を変更する
    func setOutputMethod(_ method: OutputMethod) {
        outputMethod = method
    }

    /// 出力失敗を記録する
    func failOutput(error: Error) {
        status = .failed
        eventPublisher.send(.textOutputFailed(outputId: outputId, error: error))
    }
}
