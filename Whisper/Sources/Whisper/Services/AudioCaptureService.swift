import Foundation
import AVFoundation
import Combine

// MARK: - AudioStreamOutput Protocol（Unit 2 境界インターフェース）

/// Unit 2（音声認識エンジン）への音声データストリーム出力インターフェース
protocol AudioStreamOutput: AnyObject {
    /// 音声バッファを受信する
    func didReceiveAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime)
    /// 音声ストリームが開始された
    func didStartStream()
    /// 音声ストリームが停止された
    func didStopStream()
}

// MARK: - スタブ実装

/// Unit 2 が未実装の間のスタブ実装（ログ出力のみ）
final class StubAudioStreamOutput: AudioStreamOutput {
    func didReceiveAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        // スタブ: ログ出力のみ
    }

    func didStartStream() {
        print("[Stub] Audio stream started")
    }

    func didStopStream() {
        print("[Stub] Audio stream stopped")
    }
}

// MARK: - AudioCaptureService

/// macOS のマイクからの音声入力をキャプチャするサービス。
/// AVAudioEngine を使用してリアルタイム音声データを取得する。
@MainActor
final class AudioCaptureService: ObservableObject {

    // MARK: - 属性

    private let audioEngine = AVAudioEngine()
    private var isCapturing = false

    /// Unit 2 への音声ストリーム出力先
    var streamOutput: AudioStreamOutput = StubAudioStreamOutput()

    // MARK: - 振る舞い

    /// マイクからの音声キャプチャを開始する
    func startCapture() {
        guard !isCapturing else { return }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            Task { @MainActor in
                self?.streamOutput.didReceiveAudioBuffer(buffer, time: time)
            }
        }

        do {
            try audioEngine.start()
            isCapturing = true
            streamOutput.didStartStream()
            print("[AudioCaptureService] Capture started")
        } catch {
            print("[AudioCaptureService] Failed to start capture: \(error)")
        }
    }

    /// マイクからの音声キャプチャを停止する
    func stopCapture() {
        guard isCapturing else { return }

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isCapturing = false
        streamOutput.didStopStream()
        print("[AudioCaptureService] Capture stopped")
    }
}
