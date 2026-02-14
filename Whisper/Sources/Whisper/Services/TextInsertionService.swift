import Foundation
import AppKit
import Carbon.HIToolbox

// MARK: - TextInsertionService

/// クリップボード経由でアクティブなテキストフィールドにテキストを挿入するサービス。
/// NSPasteboard + CGEvent（Command+V）方式を使用。
@MainActor
final class TextInsertionService: ObservableObject {

    // MARK: - テキスト挿入（クリップボード経由ペースト）

    /// アクティブなテキストフィールドにテキストを挿入する
    /// - Parameter text: 挿入するテキスト
    /// - Returns: 挿入に成功した場合 true
    @discardableResult
    func insertText(_ text: String) -> Bool {
        // 1. 現在のクリップボード内容を退避
        let pasteboard = NSPasteboard.general
        let savedItems = pasteboard.pasteboardItems?.compactMap { item -> (String, Data)? in
            guard let type = item.types.first,
                  let data = item.data(forType: type) else { return nil }
            return (type.rawValue, data)
        }

        // 2. クリップボードにテキストを設定
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // 3. Command+V キーイベントを発行
        let success = simulatePaste()

        // 4. 少し待ってからクリップボード内容を復元
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let savedItems = savedItems, !savedItems.isEmpty {
                pasteboard.clearContents()
                for (typeString, data) in savedItems {
                    let type = NSPasteboard.PasteboardType(typeString)
                    pasteboard.setData(data, forType: type)
                }
            }
        }

        if success {
            print("[TextInsertionService] Text inserted successfully")
        } else {
            print("[TextInsertionService] Failed to insert text")
        }

        return success
    }

    // MARK: - クリップボードコピー

    /// テキストをクリップボードにコピーする
    /// - Parameter text: コピーするテキスト
    /// - Returns: コピーに成功した場合 true
    @discardableResult
    func copyToClipboard(_ text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)

        if success {
            print("[TextInsertionService] Text copied to clipboard")
        } else {
            print("[TextInsertionService] Failed to copy to clipboard")
        }

        return success
    }

    // MARK: - アクセシビリティ権限

    /// アクセシビリティ権限が付与されているかを確認する
    static func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        return AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Private

    /// Command+V キーのシミュレーション
    private func simulatePaste() -> Bool {
        // Key down: Command + V
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true) else {
            return false
        }
        keyDownEvent.flags = .maskCommand
        keyDownEvent.post(tap: .cghidEventTap)

        // Key up: Command + V
        guard let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false) else {
            return false
        }
        keyUpEvent.flags = .maskCommand
        keyUpEvent.post(tap: .cghidEventTap)

        return true
    }
}
