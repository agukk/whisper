import Foundation
import Combine

// MARK: - Language（言語）

/// 対応する言語を表す値オブジェクト
enum Language: String, CaseIterable, Equatable, Hashable {
    /// 日本語
    case japanese = "ja-JP"
    /// 英語
    case english = "en-US"

    /// 表示用の名前
    var displayName: String {
        switch self {
        case .japanese: return "日本語"
        case .english: return "English"
        }
    }
}

// MARK: - RecognitionSegment（認識セグメント）

/// 認識結果を構成する、同一言語の連続テキスト区間を表す値オブジェクト
struct RecognitionSegment: Equatable {
    /// 認識されたテキスト
    let text: String
    /// このセグメントの言語
    let language: Language
    /// セグメントの出現順序
    let order: Int
}

// MARK: - ドメインイベント

/// RecognitionResult が発行するドメインイベント
enum RecognitionResultEvent {
    /// 認識が完了し、結果が確定した
    case recognitionCompleted(resultId: UUID, fullText: String, segments: [RecognitionSegment])
}

// MARK: - RecognitionResult（認識結果）

/// 音声認識エンジンが生成した認識結果を表すエンティティ。
/// 認識されたテキストは言語ごとのセグメントに分割され、各セグメントに言語ラベルが付与される。
///
/// ## ビジネスルール
/// - 各セグメントには対応する言語の句読点が適切に挿入されている
/// - 日英混合の発話では言語の切り替わりが自動検出され、別セグメントとして分割される
/// - セグメントの order は発話の時系列順を保持する
@MainActor
final class RecognitionResult: ObservableObject {

    // MARK: - 属性

    let resultId: UUID
    @Published private(set) var segments: [RecognitionSegment]
    let createdAt: Date

    // MARK: - ドメインイベントパブリッシャー

    let eventPublisher = PassthroughSubject<RecognitionResultEvent, Never>()

    // MARK: - 初期化

    init(resultId: UUID = UUID(), segments: [RecognitionSegment] = []) {
        self.resultId = resultId
        self.segments = segments
        self.createdAt = Date()
    }

    // MARK: - 導出属性

    /// 全セグメントを連結した完全なテキスト
    var fullText: String {
        segments
            .sorted { $0.order < $1.order }
            .map { $0.text }
            .joined()
    }

    // MARK: - 振る舞い

    /// 認識セグメントを追加する
    func addSegment(_ segment: RecognitionSegment) {
        segments.append(segment)
    }

    /// 全セグメントを連結した完全なテキストを返す
    func getFullText() -> String {
        return fullText
    }

    /// 指定言語のセグメントのみを返す
    func getSegmentsByLanguage(_ language: Language) -> [RecognitionSegment] {
        segments.filter { $0.language == language }
    }

    /// 認識完了を通知する
    func finalize() {
        eventPublisher.send(.recognitionCompleted(
            resultId: resultId,
            fullText: fullText,
            segments: segments
        ))
    }
}
