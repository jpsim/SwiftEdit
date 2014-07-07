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

class SwiftSyntaxHighligher: NSObject, NSTextStorageDelegate, NSLayoutManagerDelegate {
    var textStorage : NSTextStorage?
    var textView : NSTextView?
    var scrollView: NSScrollView?
    let swiftStyles = [
        // Same as Xcode's default theme
        "source.lang.swift.syntaxtype.comment": NSColor(red: 0, green: 0.514, blue: 0.122, alpha: 1),
        "source.lang.swift.syntaxtype.identifier": NSColor.blackColor(),
        "source.lang.swift.syntaxtype.keyword": NSColor(red: 0.796, green: 0.208, blue: 0.624, alpha: 1),
        "source.lang.swift.syntaxtype.typeidentifier": NSColor(red: 0.478, green: 0.251, blue: 0.651, alpha: 1),
        "source.lang.swift.syntaxtype.string": NSColor(red: 0.918, green: 0.216, blue: 0.071, alpha: 1),
        "source.lang.swift.syntaxtype.number": NSColor(red: 0.22, green: 0.18, blue: 0.827, alpha: 1),
        "source.lang.swift.syntaxtype.attribute.builtin": NSColor(red: 0.796, green: 0.208, blue: 0.624, alpha: 1)
    ]

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
        let glyphRange = layoutManager.glyphRangeForBoundingRect(textVisibleRect,
            inTextContainer: container)
        return layoutManager.characterRangeForGlyphRange(glyphRange,
            actualGlyphRange: nil)
    }
    
    func parse(sender: AnyObject?) {
        let tokens = parseString(textStorage!.string)

        if tokens == nil {
            return
        }

        let range = visibleRange()
        let layoutManagerList = textStorage!.layoutManagers as NSLayoutManager[]
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

    func parseString(string: String) -> Token[]? {
        // Save string to temporary file
        let tmpFilePath = NSTemporaryDirectory().stringByAppendingPathComponent("tmp.swift")
        NSFileManager.defaultManager().createFileAtPath(tmpFilePath,
            contents: string.dataUsingEncoding(NSUTF8StringEncoding),
            attributes: nil)

        // Shell out to SourceKit to obtain syntax map for string
        let syntaxPipe = NSPipe()

        let syntaxTask = NSTask()
        syntaxTask.launchPath = "/usr/bin/xcrun"
        syntaxTask.arguments = ["sourcekitd-test", "-req=syntax-map", tmpFilePath]
        syntaxTask.standardOutput = syntaxPipe

        syntaxTask.launch()
        syntaxTask.waitUntilExit()

        var syntaxMap = NSMutableString(data: syntaxPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: NSUTF8StringEncoding)
        // Strings in JSON aren't yet quoted. Add quotation marks here.
        syntaxMap.replaceOccurrencesOfString("(key|source)\\.[^:,]*",
            withString: "\"$0\"",
            options: .RegularExpressionSearch,
            range: NSRange(location: 0, length: syntaxMap.length))

        var error: NSError?

        let jsonObject: NSDictionary! = NSJSONSerialization.JSONObjectWithData(syntaxMap.dataUsingEncoding(NSUTF8StringEncoding),
            options: NSJSONReadingOptions(0),
            error: &error) as? NSDictionary

        if error != nil {
            println("error parsing JSON: \(syntaxMap)")
        } else {
            if let tokenDicts = jsonObject["key.syntaxmap"] as? NSDictionary[] {
                var tokens = Token[]()
                for token in tokenDicts {
                    let location = (token["key.offset"] as NSNumber).integerValue
                    let length = (token["key.length"] as NSNumber).integerValue
                    tokens += Token(kind: token["key.kind"] as String, range: NSRange(location: location, length: length))
                }
                return tokens
            }
        }
        return nil
    }
    
    func textStorageDidProcessEditing(aNotification: NSNotification) {
        GCD.asyncExec {
            self.parse(self)
        }
    }
    
    func layoutManager(layoutManager: NSLayoutManager!, shouldUseTemporaryAttributes attrs: NSDictionary!, forDrawingToScreen toScreen: Bool, atCharacterIndex charIndex: Int, effectiveRange effectiveCharRange: CMutablePointer<NSRange>) -> NSDictionary! {
        
        if toScreen {
            if let type = attrs[SWIFT_ELEMENT_TYPE_KEY] as? String {
                if let style = swiftStyles[type] {
                    return [NSForegroundColorAttributeName: style]
                } else {
                    println("\(type) is not a valid style")
                }
            }
        }
        return attrs
    }

}
