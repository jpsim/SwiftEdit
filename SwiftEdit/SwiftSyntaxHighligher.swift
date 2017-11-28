//
//  SwiftSyntaxHighligher.swift
//  SwiftEdit
//
//  Created by JP Simard on 06/07/2014.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Cocoa
import SourceKittenFramework

extension NSAttributedStringKey {
    static let swiftElementType = NSAttributedStringKey(rawValue: "swiftElementType")
}

struct Token {
    let kind: String
    let range: NSRange
}

extension SyntaxKind {
    var colorValue: NSColor {
        switch self {
        case .keyword:
            return NSColor(red: 0.796, green: 0.208, blue: 0.624, alpha: 1)
        case .identifier:
            return .black
        case .typeidentifier:
            return NSColor(red: 0.478, green: 0.251, blue: 0.651, alpha: 1)
        case .string:
            return NSColor(red: 0.918, green: 0.216, blue: 0.071, alpha: 1)
        case .number:
            return NSColor(red: 0.22, green: 0.18, blue: 0.827, alpha: 1)
        case .comment, .commentMark, .commentURL, .docComment, .docCommentField:
            return NSColor(red: 0, green: 0.514, blue: 0.122, alpha: 1)
        case .attributeBuiltin:
            return NSColor(red: 0.796, green: 0.208, blue: 0.624, alpha: 1)
        default:
            return .green
        }
    }
}

class SwiftSyntaxHighligher: NSObject, NSTextStorageDelegate, NSLayoutManagerDelegate {
    var textStorage: NSTextStorage?
    var textView: NSTextView?
    var scrollView: NSScrollView?

    convenience init(textStorage: NSTextStorage, textView: NSTextView, scrollView: NSScrollView) {
        self.init()
        self.textStorage = textStorage
        self.scrollView = scrollView
        self.textView = textView

        textStorage.delegate = self
        parse()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func visibleRange() -> NSRange {
        let container = textView!.textContainer
        let layoutManager = textView!.layoutManager
        let textVisibleRect = scrollView!.contentView.bounds
        let glyphRange = layoutManager!.glyphRange(forBoundingRect: textVisibleRect,
                                                   in: container!)
        return layoutManager!.characterRange(forGlyphRange: glyphRange,
            actualGlyphRange: nil)
    }

    func parse() {
        guard let tokens = parseString(string: textStorage!.string) else {
            return
        }

        let range = visibleRange()
        let layoutManagerList = textStorage!.layoutManagers as [NSLayoutManager]
        for layoutManager in layoutManagerList {
            layoutManager.delegate = self
            layoutManager.removeTemporaryAttribute(.swiftElementType,
                                                   forCharacterRange: range)

            for token in tokens {
                layoutManager.addTemporaryAttributes([.swiftElementType: token.kind],
                                                     forCharacterRange: token.range)
            }
        }
    }

    func parseString(string: String) -> [Token]? {
        if string.isEmpty {
            return []
        }

        let syntaxMap = SyntaxMap(file: File(contents: string))

        return syntaxMap.tokens.map { token in
            return Token(kind: token.type, range: NSRange(location: token.offset, length: token.length))
        }
    }

    override func textStorageDidProcessEditing(_ notification: Notification) {
        DispatchQueue.main.async() {
            self.parse()
        }
    }

    func layoutManager(_ layoutManager: NSLayoutManager, shouldUseTemporaryAttributes attrs: [NSAttributedStringKey : Any] = [:], forDrawingToScreen toScreen: Bool, atCharacterIndex charIndex: Int, effectiveRange effectiveCharRange: NSRangePointer?) -> [NSAttributedStringKey : Any]? {
        if let type = attrs[.swiftElementType] as? String, toScreen {
            if let style = SyntaxKind(rawValue: type)?.colorValue {
                return [NSAttributedStringKey.foregroundColor: style]
            } else {
                print("\(type) is not a valid style")
            }
        }
        return attrs
    }
}
