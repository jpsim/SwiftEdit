//
//  RulerView.swift
//  SwiftEdit
//
//  Created by Scott Horn on 14/06/2014.
//  Copyright (c) 2014 Scott Horn. All rights reserved.
//

import Cocoa

let DEFAULT_THICKNESS: CGFloat = 25
let RULER_MARGIN: CGFloat = 11

class RulerView: NSRulerView {
    var _lineIndices: [Int]? {
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                let newThickness = self.calculateRuleThickness()
                if fabs(self.ruleThickness - newThickness) > 1 {
                    self.ruleThickness = CGFloat(ceil(newThickness))
                    self.needsDisplay = true
                }
            }
        }
    }
    var lineIndices: [Int]? {
        get {
            if _lineIndices == nil {
                calculateLines()
            }
            return _lineIndices
        }
    }
    var textView: NSTextView? { return clientView as? NSTextView }

    override var opaque: Bool { return false }
    override var clientView: NSView? {
        willSet {
            let center = NSNotificationCenter.defaultCenter()
            if let oldView = clientView as? NSTextView where oldView != newValue {
                center.removeObserver(self, name: NSTextDidEndEditingNotification, object: oldView.textStorage)
                center.removeObserver(self, name: NSViewBoundsDidChangeNotification, object: scrollView?.contentView)
            }
            center.addObserver(self, selector: "textDidChange:", name: NSTextDidChangeNotification, object: newValue)
            scrollView?.contentView.postsBoundsChangedNotifications = true
            center.addObserver(self, selector: "boundsDidChange:", name: NSViewBoundsDidChangeNotification, object: scrollView?.contentView)
            invalidateLineIndices()
        }
    }

    override init(scrollView: NSScrollView?, orientation: NSRulerOrientation) {
        super.init(scrollView: scrollView, orientation:orientation)
        clientView = scrollView?.documentView as? NSView
        ruleThickness = DEFAULT_THICKNESS
        needsDisplay = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    @objc func boundsDidChange(notification: NSNotification) {
        needsDisplay = true
    }

    func textDidChange(notification: NSNotification) {
        invalidateLineIndices()
        needsDisplay = true
    }

    override func drawRect(dirtyRect: NSRect) {
        drawHashMarksAndLabelsInRect(dirtyRect)
    }

    func invalidateLineIndices() {
        _lineIndices = nil
    }

    func lineNumberForCharacterIndex(index: Int) -> Int {
        var left = 0, right = lineIndices!.count
        while right - left > 1 {
            let mid = (left + right) / 2
            let lineIndex = lineIndices![mid]
            if index < lineIndex {
                right = mid
            } else if index > lineIndex {
                left = mid
            } else {
                return mid + 1
            }
        }
        return left + 1
    }

    func calculateRuleThickness() -> CGFloat {
        let digitWidth = (String(lineIndices?.last ?? 0) as NSString).sizeWithAttributes(textAttributes()).width * 2 + RULER_MARGIN
        return max(digitWidth, DEFAULT_THICKNESS)
    }

    func calculateLines() {
        var lineIndices = [Int]()
        guard let textView = textView else {
            return
        }
        let text = textView.string! as NSString
        let textLength = text.length
        var totalLines = 0
        var charIndex = 0
        repeat {
            lineIndices.append(charIndex)
            charIndex = NSMaxRange(text.lineRangeForRange(NSMakeRange(charIndex, 0)))
            totalLines++
        } while charIndex < textLength

        // Check for trailing return
        var lineEndIndex = 0, contentEndIndex = 0
        let lastObject = lineIndices[lineIndices.count - 1]
        text.getLineStart(nil, end: &lineEndIndex, contentsEnd: &contentEndIndex, forRange: NSMakeRange(lastObject, 0))
        if contentEndIndex < lineEndIndex {
            lineIndices.append(lineEndIndex)
        }
        _lineIndices = lineIndices
    }

    override func drawHashMarksAndLabelsInRect(rect: NSRect) {
        guard let textView = textView else {
            return
        }

        // Make background
        let docRect = convertRect(clientView!.bounds, fromView: clientView)
        let y = docRect.origin.y
        let height = docRect.size.height
        let width = bounds.size.width
        NSColor(calibratedRed: 0.969, green: 0.969, blue: 0.969, alpha: 1).set()
        NSRectFill(NSMakeRect(0, y, width, height))

        // Code folding area
        NSRectFill(NSMakeRect(width - 8, y, 8, height))

        // Seperator/s
        NSColor(calibratedRed: 0.902, green: 0.902, blue: 0.902, alpha: 1).set()
        var line = NSBezierPath()
        line.moveToPoint(NSMakePoint(width - 8.5, y))
        line.lineToPoint(NSMakePoint(width - 8.5, y + height))
        line.lineWidth = 1
        line.stroke()

        line = NSBezierPath()
        line.moveToPoint(NSMakePoint(width - 0.5, y))
        line.lineToPoint(NSMakePoint(width - 0.5, y + height))
        line.lineWidth = 1
        line.stroke()

        let layoutManager = textView.layoutManager
        let container = textView.textContainer
        let nullRange = NSMakeRange(NSNotFound, 0)
        var lineRectCount = 0

        let textVisibleRect = scrollView!.contentView.bounds
        let rulerBounds = bounds
        let textInset = textView.textContainerInset.height

        let glyphRange = layoutManager!.glyphRangeForBoundingRect(textVisibleRect, inTextContainer: container!)
        let charRange = layoutManager!.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)

        let startChange = lineNumberForCharacterIndex(charRange.location)
        let endChange = lineNumberForCharacterIndex(NSMaxRange(charRange))
        for var lineNumber = startChange; lineNumber <= endChange; lineNumber++ {
            let charIndex = lineIndices![lineNumber - 1]
            let lineRectsForRange = layoutManager!.rectArrayForCharacterRange(
                NSMakeRange(charIndex, 0),
                withinSelectedCharacterRange: nullRange,
                inTextContainer: container!,
                rectCount: &lineRectCount)
            if lineRectCount > 0 {
                let ypos = textInset + NSMinY(lineRectsForRange[0]) - NSMinY(textVisibleRect)
                let labelText = NSString(format: "%ld", lineNumber)
                let labelSize = labelText.sizeWithAttributes(textAttributes())

                let lineNumberRect = NSMakeRect( NSWidth(rulerBounds) - labelSize.width - RULER_MARGIN,
                                                 ypos + (NSHeight(lineRectsForRange[0]) - labelSize.height) / 2,
                                                 NSWidth(rulerBounds) - RULER_MARGIN * 2,
                                                 NSHeight(lineRectsForRange[0]) )

                labelText.drawInRect(lineNumberRect, withAttributes: textAttributes())
            }

            // we are past the visible range so exit for
            if charIndex > NSMaxRange(charRange) {
                break
            }
        }
    }


    func textAttributes() -> [String: AnyObject] {
        return [
            NSFontAttributeName: NSFont.labelFontOfSize(NSFont.systemFontSizeForControlSize(.MiniControlSize)),
            NSForegroundColorAttributeName: NSColor(calibratedWhite: 0.42, alpha: 1)
        ]
    }
}
