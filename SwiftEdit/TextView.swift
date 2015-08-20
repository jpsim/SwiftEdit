//
//  TextView.swift
//  SwiftEdit
//
//  Created by Scott Horn on 17/06/2014.
//  Copyright (c) 2014 Scott Horn. All rights reserved.
//

import Cocoa

class TextView: NSTextView {
    lazy var guidePosition: CGFloat = {
        var lineRectCount = 0
        var stripSpace = false
        if self.string!.utf16.count < 1 {
            self.string = " "
            stripSpace = true
        }
        let lineRectsForRange = self.layoutManager!.rectArrayForCharacterRange(NSMakeRange(0, 1),
            withinSelectedCharacterRange: NSMakeRange(NSNotFound, 0),
            inTextContainer: self.textContainer!,
            rectCount: &lineRectCount)
        self.string = stripSpace ? "" : self.string
        let margin = lineRectsForRange[0].origin.x
        let size = "8".sizeWithAttributes([
            NSFontAttributeName: NSFont.userFixedPitchFontOfSize(NSFont.smallSystemFontSize())!
            ]).width
        return CGFloat(Int(margin + size * 80)) + 0.5
    }()

    override func drawRect(dirtyRect: NSRect) {
        NSColor.whiteColor().set()
        NSRectFill(bounds)
        super.drawRect(dirtyRect)
    }

    override func drawViewBackgroundInRect(rect: NSRect) {
        drawPageGuideBackgroundAt(guidePosition)
        drawHighlightedLine()
        drawPageGuideLineAt(guidePosition)
    }

    func drawHighlightedLine() {
        guard let text = textStorage?.string as NSString? where selectedRange.location <= text.length else {
            return
        }
        let lineRange = text.lineRangeForRange(NSMakeRange(selectedRange.location, 0))
        NSColor(calibratedRed: 0.992, green: 1.000, blue: 0.800, alpha: 1).setFill()
        NSRectFill(rectForRange(lineRange))
    }

    func drawPageGuideBackgroundAt(position: CGFloat) {
        NSColor(calibratedRed: 0.988 , green: 0.988 , blue: 0.988 , alpha: 1).set()
        NSRectFill(NSMakeRect(position, bounds.origin.y,
            bounds.size.width - position, bounds.size.height))
    }

    func drawPageGuideLineAt(position: CGFloat) {
        NSColor(calibratedRed: 0.863, green: 0.859, blue: 0.863, alpha: 1).set()
        let line = NSBezierPath()
        line.moveToPoint(NSPoint(x: position, y: 0))
        line.lineToPoint(NSPoint(x: position, y: bounds.size.height))
        line.lineWidth = 1
        line.stroke()
    }

    func rectForRange(range: NSRange) -> NSRect {
        var lineRectCount = 0
        let lineRectsForRange = layoutManager!.rectArrayForCharacterRange(range,
            withinSelectedCharacterRange: NSMakeRange(NSNotFound, 0),
            inTextContainer: textContainer!,
            rectCount: &lineRectCount)

        if lineRectCount < 1 {
            return NSZeroRect
        }
        let y = lineRectsForRange[0].origin.y
        let h = lineRectsForRange[0].size.height
        let w = bounds.size.width
        return NSOffsetRect(NSMakeRect(0, y, w, h), textContainerOrigin.x, textContainerOrigin.y)
    }
}
