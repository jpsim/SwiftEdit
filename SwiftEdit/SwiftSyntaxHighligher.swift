//
//  SwiftSyntaxHighligher.swift
//  SwiftEdit
//
//  Created by JP Simard on 06/07/2014.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Cocoa

let SWIFT_ELEMENT_TYPE_KEY = "swiftElementType"

struct Token {
    let kind: String
    let range: NSRange
}

public enum SyntaxKind: String {
    /// `argument`.
    case Argument = "source.lang.swift.syntaxtype.argument"
    /// `attribute.builtin`.
    case AttributeBuiltin = "source.lang.swift.syntaxtype.attribute.builtin"
    /// `attribute.id`.
    case AttributeID = "source.lang.swift.syntaxtype.attribute.id"
    /// `buildconfig.id`.
    case BuildconfigID = "source.lang.swift.syntaxtype.buildconfig.id"
    /// `buildconfig.keyword`.
    case BuildconfigKeyword = "source.lang.swift.syntaxtype.buildconfig.keyword"
    /// `comment`.
    case Comment = "source.lang.swift.syntaxtype.comment"
    /// `comment.mark`.
    case CommentMark = "source.lang.swift.syntaxtype.comment.mark"
    /// `comment.url`.
    case CommentURL = "source.lang.swift.syntaxtype.comment.url"
    /// `doccomment`.
    case DocComment = "source.lang.swift.syntaxtype.doccomment"
    /// `doccomment.field`.
    case DocCommentField = "source.lang.swift.syntaxtype.doccomment.field"
    /// `identifier`.
    case Identifier = "source.lang.swift.syntaxtype.identifier"
    /// `keyword`.
    case Keyword = "source.lang.swift.syntaxtype.keyword"
    /// `number`.
    case Number = "source.lang.swift.syntaxtype.number"
    /// `objectliteral`.
    case Objectliteral = "source.lang.swift.syntaxtype.objectliteral"
    /// `parameter`.
    case Parameter = "source.lang.swift.syntaxtype.parameter"
    /// `placeholder`.
    case Placeholder = "source.lang.swift.syntaxtype.placeholder"
    /// `string`.
    case String = "source.lang.swift.syntaxtype.string"
    /// `string_interpolation_anchor`.
    case StringInterpolationAnchor = "source.lang.swift.syntaxtype.string_interpolation_anchor"
    /// `typeidentifier`.
    case Typeidentifier = "source.lang.swift.syntaxtype.typeidentifier"

    var colorValue: NSColor {
        switch self {
        case .Keyword:
            return NSColor(red: 0.796, green: 0.208, blue: 0.624, alpha: 1)
        case .Identifier:
            return NSColor.blackColor()
        case .Typeidentifier:
            return NSColor(red: 0.478, green: 0.251, blue: 0.651, alpha: 1)
        case .String:
            return NSColor(red: 0.918, green: 0.216, blue: 0.071, alpha: 1)
        case .Number:
            return NSColor(red: 0.22, green: 0.18, blue: 0.827, alpha: 1)
        case .Comment, .CommentMark, .CommentURL, .DocComment, .DocCommentField:
            return NSColor(red: 0, green: 0.514, blue: 0.122, alpha: 1)
        case .AttributeBuiltin:
            return NSColor(red: 0.796, green: 0.208, blue: 0.624, alpha: 1)
        default:
            return NSColor.greenColor()
        }
    }
}

class SwiftSyntaxHighligher: NSObject, NSTextStorageDelegate, NSLayoutManagerDelegate {
    var textStorage : NSTextStorage?
    var textView : NSTextView?
    var scrollView: NSScrollView?

    convenience init(textStorage: NSTextStorage, textView: NSTextView, scrollView: NSScrollView) {
        self.init()
        self.textStorage = textStorage
        self.scrollView = scrollView
        self.textView = textView
        
        textStorage.delegate = self
//        scrollView.contentView.postsBoundsChangedNotifications = true
//        NSNotificationCenter.defaultCenter().addObserver(self,
//            selector: "textStorageDidProcessEditing:",
//            name: NSViewBoundsDidChangeNotification,
//            object: scrollView.contentView)
        parse(nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func visibleRange() -> NSRange {
        let container = textView!.textContainer
        let layoutManager = textView!.layoutManager
        let textVisibleRect = scrollView!.contentView.bounds
        let glyphRange = layoutManager!.glyphRangeForBoundingRect(textVisibleRect,
            inTextContainer: container!)
        return layoutManager!.characterRangeForGlyphRange(glyphRange,
            actualGlyphRange: nil)
    }
    
    func parse(sender: AnyObject?) {
        let tokens = parseString(textStorage!.string)

        if tokens == nil {
            return
        }

        let range = visibleRange()
        let layoutManagerList = textStorage!.layoutManagers as [NSLayoutManager]
        for layoutManager in layoutManagerList {
            layoutManager.delegate = self
            layoutManager.removeTemporaryAttribute(SWIFT_ELEMENT_TYPE_KEY,
                forCharacterRange: range)

            for token in tokens! {
                layoutManager.addTemporaryAttributes([SWIFT_ELEMENT_TYPE_KEY: token.kind],
                    forCharacterRange: token.range)
            }
        }
    }

    func parseString(string: String) -> [Token]? {
        // Save string to temporary file
        let tmpFilePath = NSTemporaryDirectory().stringByAppendingPathComponent("tmp.swift")
        NSFileManager.defaultManager().createFileAtPath(tmpFilePath,
            contents: string.dataUsingEncoding(NSUTF8StringEncoding),
            attributes: nil)

        // Shell out to SourceKit to obtain syntax map for string
        let syntaxPipe = NSPipe()

        let syntaxTask = NSTask()
        syntaxTask.launchPath = "/usr/local/bin/sourcekitten"
        syntaxTask.arguments = ["syntax", "--file", tmpFilePath]
        syntaxTask.standardOutput = syntaxPipe

        syntaxTask.launch()
        syntaxTask.waitUntilExit()

        let syntaxMap = NSMutableString(data: syntaxPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: NSUTF8StringEncoding)

        let tokens = try! NSJSONSerialization.JSONObjectWithData(syntaxMap!.dataUsingEncoding(NSUTF8StringEncoding)!,
            options: []) as! [NSDictionary]
        return tokens.map { token in
            let offset = token["offset"] as! Int
            let length = token["length"] as! Int
            let type = token["type"] as! String
            return Token(kind: type, range: NSRange(location: offset, length: length))
        }
    }

    override func textStorageDidProcessEditing(aNotification: NSNotification) {
        GCD.asyncExec {
            self.parse(self)
        }
    }

    func layoutManager(layoutManager: NSLayoutManager, shouldUseTemporaryAttributes attrs: [String : AnyObject], forDrawingToScreen toScreen: Bool, atCharacterIndex charIndex: Int, effectiveRange effectiveCharRange: NSRangePointer) -> [String : AnyObject]? {
        if toScreen {
            if let type = attrs[SWIFT_ELEMENT_TYPE_KEY] as? String {
                if let style = SyntaxKind(rawValue: type)?.colorValue {
                    return [NSForegroundColorAttributeName: style]
                } else {
                    print("\(type) is not a valid style")
                }
            }
        }
        return attrs
    }
}
