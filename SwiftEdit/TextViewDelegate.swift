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
    var isDeleting = false
    
    func textView(textView: NSTextView!, doCommandBySelector commandSelector: Selector) -> Bool {
        switch commandSelector {
        case "deleteBackward:":
            if isDeleting {
                return false
            }
            isDeleting = true
            let range = textView.selectedRange
            let text = textView.textStorage!.string as NSString
            if range.location == 0 || range.length > 0 {
                isDeleting = false
                return false
            }
            if range.location > 0  {
                let c = String(Array(arrayLiteral: text as String)[range.location - 1])
                if c != " " {
                    isDeleting = false
                    return false
                }
            }
            let lineRange = text.lineRangeForRange(range)
            var mod = Int((range.location - lineRange.location) % HMTabWidth)
            mod = (mod == 0) ? HMTabWidth : mod
            for var i = 0; i < mod; i++ {
                let charIndex = (range.location - 1) - i
                let c = String(Array(arrayLiteral: text as String)[charIndex])
                if c != " " {
                    break
                }
                textView.doCommandBySelector(commandSelector)
                if charIndex == 0 {
                    break
                }
            }
            isDeleting = false
            return true
            
        case "insertNewline:":
            var text = textView.textStorage!.string as NSString
            let range = textView.selectedRange
            let lineRange = text.lineRangeForRange(range)
            text = text.substringWithRange(NSMakeRange(lineRange.location, range.location - lineRange.location))
            var shouldIndent = false
            for var i = text.length - 1; i >= 0; i-- {
                let c = String(Array(arrayLiteral: text as String)[i])
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
                let c = String(Array(arrayLiteral: text as String)[i])
                if c == " " {
                    indent += " "
                } else if c == "\t" {
                    indent += "\t"
                } else {
                    break
                }
            }
            if shouldIndent {
                var mod = Int(indent.utf16.count % HMTabWidth)
                mod = (mod == 0) ? HMTabWidth : HMTabWidth - mod
                for var i = 0; i < mod; i++ {
                    indent += " "
                }
            }
            textView.insertText("\n\(indent)")
            return true
            
        case "insertBacktab:":
            let range = textView.selectedRange
            let text = textView.textStorage!.string as NSString
            let lineRange = text.lineRangeForRange(range)
            let lines = (text.substringWithRange(lineRange) as NSString).mutableCopy() as! NSMutableString
            var paraStart = 0, paraEnd = 0, contentsEnd = 0, spaces = 0
            while paraEnd < lines.length {
                lines.getParagraphStart(&paraStart,
                    end: &paraEnd,
                    contentsEnd: &contentsEnd,
                    forRange: NSMakeRange(paraEnd, 0))
                var location = paraStart
                for spaces = 0; location < lines.length; location++ {
                    let c = String(Array(arrayLiteral: lines as String)[location])
                    if c != " " || spaces == 4 {
                        break
                    }
                    spaces++
                }
                lines.replaceCharactersInRange(NSMakeRange(paraStart, location - paraStart), withString: "")
            }
            if textView.shouldChangeTextInRange(lineRange, replacementString: lines as String) {
                textView.textStorage!.replaceCharactersInRange(lineRange, withString: lines as String)
                textView.didChangeText()
            }
            if range.length > 0 {
                textView.setSelectedRange(NSMakeRange(lineRange.location, lines.length))
            } else {
                let loc1 = range.location - spaces
                let loc2 = lineRange.location
                textView.setSelectedRange(NSMakeRange(loc1 > loc2 ? loc1 : loc2, 0))
            }
            return true
        case "insertTab:":
            let column = (textView as! TextView).currentColumn
            var spaces : Int
            var indent = ""
            var text = textView.textStorage!.string as NSString
            let range = textView.selectedRange
            let lineRange = text.lineRangeForRange(range)
            var location = 0
            
            text = text.substringWithRange(NSMakeRange(range.location, lineRange.length - (range.location - lineRange.location)))
            for var i = 0; i < text.length; i++ {
                let c = String(Array(arrayLiteral: text as String)[i])
                if c != " " {
                    break
                }
                location++
            }
            textView.selectedRange = NSMakeRange(range.location + location, 0)
            spaces = Int(column % HMTabWidth)
            for var i = HMTabWidth; i > spaces; i-- {
                indent += " "
            }
            if range.length > 0 {
                let lines = (textView.textStorage!.string as NSString).mutableCopy() as! NSMutableString
                var paraStart = 0, paraEnd = 0, contentsEnd = 0
                while paraEnd < lines.length {
                    lines.getParagraphStart(&paraStart,
                        end: &paraEnd,
                        contentsEnd: &contentsEnd,
                        forRange: NSMakeRange(paraEnd, 0))
                    lines.replaceCharactersInRange(NSMakeRange(paraStart,0), withString: indent as String)
                    paraEnd += indent.utf16.count
                }
                
                if textView.shouldChangeTextInRange(lineRange, replacementString: lines as String) {
                    textView.textStorage!.replaceCharactersInRange(lineRange, withString: lines as String)
                    textView.didChangeText()
                }
                textView.setSelectedRange(NSMakeRange(lineRange.location, lines.length))
                return true
            }
            textView.insertText(indent)
            return true
        default:
            return false
        }
    }
}
