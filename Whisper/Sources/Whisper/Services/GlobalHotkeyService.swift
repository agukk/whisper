import Foundation
import Cocoa
import Combine

// MARK: - GlobalHotkeyService

/// macOS のグローバルキーイベントを監視し、fn（Globe）キーの押下/解放を検出するサービス。
/// どのアプリケーションがフォーカスされていても、グローバルに動作する。
@MainActor
final class GlobalHotkeyService: ObservableObject {

    // MARK: - 属性

    private var flagsChangedMonitor: Any?
    private var localFlagsChangedMonitor: Any?
    private var isFnKeyPressed = false

    /// fn キーが押された時のコールバック
    var onKeyDown: (() -> Void)?
    /// fn キーが離された時のコールバック
    var onKeyUp: (() -> Void)?

    // MARK: - 振る舞い

    /// fn（Globe）キーのグローバル監視を開始する
    func startMonitoring() {
        // グローバルイベント監視（他のアプリがフォーカス中）
        flagsChangedMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor in
                self?.handleFlagsChanged(event)
            }
        }

        // ローカルイベント監視（自アプリがフォーカス中）
        localFlagsChangedMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor in
                self?.handleFlagsChanged(event)
            }
            return event
        }

        print("[GlobalHotkeyService] Monitoring started for fn (Globe) key")
    }

    /// fn（Globe）キーのグローバル監視を停止する
    func stopMonitoring() {
        if let monitor = flagsChangedMonitor {
            NSEvent.removeMonitor(monitor)
            flagsChangedMonitor = nil
        }
        if let monitor = localFlagsChangedMonitor {
            NSEvent.removeMonitor(monitor)
            localFlagsChangedMonitor = nil
        }
        isFnKeyPressed = false
        print("[GlobalHotkeyService] Monitoring stopped")
    }

    // MARK: - Private

    private func handleFlagsChanged(_ event: NSEvent) {
        let fnKeyPressed = event.modifierFlags.contains(.function)

        if fnKeyPressed && !isFnKeyPressed {
            // fn キーが押された
            isFnKeyPressed = true
            onKeyDown?()
            print("[GlobalHotkeyService] fn key pressed")
        } else if !fnKeyPressed && isFnKeyPressed {
            // fn キーが離された
            isFnKeyPressed = false
            onKeyUp?()
            print("[GlobalHotkeyService] fn key released")
        }
    }

    deinit {
        if let monitor = flagsChangedMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localFlagsChangedMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
