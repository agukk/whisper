import Testing
@testable import Whisper

@Suite("RecognitionResult Tests")
struct RecognitionResultTests {

    @Test("初期状態はセグメントが空")
    @MainActor
    func initialStateHasNoSegments() {
        let result = RecognitionResult()
        #expect(result.segments.isEmpty)
        #expect(result.fullText == "")
    }

    @Test("セグメントを追加できる")
    @MainActor
    func addSegment() {
        let result = RecognitionResult()
        let segment = RecognitionSegment(text: "こんにちは", language: .japanese, order: 0)
        result.addSegment(segment)
        #expect(result.segments.count == 1)
        #expect(result.segments[0].text == "こんにちは")
    }

    @Test("fullText は全セグメントを order 順に連結する")
    @MainActor
    func fullTextConcatenatesInOrder() {
        let result = RecognitionResult()
        result.addSegment(RecognitionSegment(text: "Hello ", language: .english, order: 0))
        result.addSegment(RecognitionSegment(text: "世界", language: .japanese, order: 1))
        #expect(result.getFullText() == "Hello 世界")
    }

    @Test("order が逆順でも fullText は正しく連結される")
    @MainActor
    func fullTextRespectsOrder() {
        let result = RecognitionResult()
        result.addSegment(RecognitionSegment(text: "世界", language: .japanese, order: 1))
        result.addSegment(RecognitionSegment(text: "Hello ", language: .english, order: 0))
        #expect(result.getFullText() == "Hello 世界")
    }

    @Test("言語別にセグメントを取得できる")
    @MainActor
    func getSegmentsByLanguage() {
        let result = RecognitionResult()
        result.addSegment(RecognitionSegment(text: "Hello", language: .english, order: 0))
        result.addSegment(RecognitionSegment(text: "こんにちは", language: .japanese, order: 1))
        result.addSegment(RecognitionSegment(text: "World", language: .english, order: 2))

        let englishSegments = result.getSegmentsByLanguage(.english)
        let japaneseSegments = result.getSegmentsByLanguage(.japanese)

        #expect(englishSegments.count == 2)
        #expect(japaneseSegments.count == 1)
        #expect(japaneseSegments[0].text == "こんにちは")
    }
}
