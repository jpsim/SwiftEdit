//
//  TextViewDelegate.swift
//  SwiftEdit
//
//  Created by Scott Horn on 19/06/2014.
//  Copyright (c) 2014 Scott Horn. All rights reserved.
//

import Cocoa

let HMTabWidth = 4

class TextViewDelegate: NSObject {
    func textView(textView: NSTextView!, doCommandBySelector commandSelector: Selector) -> Bool {
        switch commandSelector {
        case "insertNewline:":
            var text = textView.textStorage.string as NSString
            let range = textView.selectedRange
            let lineRange = text.lineRangeForRange(range)
            text = text.substringWithRange(NSMakeRange(lineRange.location, range.location - lineRange.location))
            var shouldIndent = false
            for var i = text.length - 1; i >= 0; i-- {
                let c = String(Array(text as String)[i])
                if c == " " || c == "\t" {
                    continue
                } else if c == "{" || c == "[" || c == "(" {
                    shouldIndent = true
                } else {
                    break
                }
            }
            var indent = ""
            for var i = 0; i < text.length; i++ {
                let c = String(Array(text as String)[i])
                if c == " " {
                    indent += " "
                } else if c == "\t" {
                    indent += "\t"
                } else {
                    break
                }
            }
            if shouldIndent {
                var mod = Int(indent.utf16count % HMTabWidth)
                mod = (mod == 0) ? HMTabWidth : HMTabWidth - mod
                for var i = 0; i < mod; i++ {
                    indent += " "
                }
            }
            textView.insertText("\n\(indent)")
            return true
        default:
            return false
        }
    }
}
