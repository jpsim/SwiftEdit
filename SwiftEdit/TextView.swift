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
        if self.string.utf16.count < 1 {
            self.string = " "
            stripSpace = true
        }
        let lineRectsForRange = self.layoutManager!.rectArray(forCharacterRange: NSRange(location: 0, length: 1),
                                                              withinSelectedCharacterRange: NSRange(location: NSNotFound, length: 0),
                                                              in: self.textContainer!,
                                                              rectCount: &lineRectCount)
        self.string = stripSpace ? "" : self.string
        let margin = lineRectsForRange![0].origin.x
        let size = "8".size(withAttributes: [
            NSAttributedStringKey.font: NSFont.userFixedPitchFont(ofSize: NSFont.smallSystemFontSize)!
        ]).width
        return CGFloat(Int(margin + size * 80)) + 0.5
    }()

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.set()
        bounds.fill()
        super.draw(dirtyRect)
    }

    override func drawBackground(in rect: NSRect) {
        drawPageGuideBackgroundAt(position: guidePosition)
        drawHighlightedLine()
        drawPageGuideLineAt(position: guidePosition)
    }

    func drawHighlightedLine() {
        guard let text = textStorage?.string as NSString?, selectedRange.location <= text.length else {
            return
        }
        let lineRange = text.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        NSColor(calibratedRed: 0.992, green: 1.000, blue: 0.800, alpha: 1).setFill()
        rectForRange(range: lineRange).fill()
    }

    func drawPageGuideBackgroundAt(position: CGFloat) {
        NSColor(calibratedRed: 0.988 , green: 0.988 , blue: 0.988 , alpha: 1).set()
        NSRect(x: position, y: bounds.origin.y,
               width: bounds.size.width - position, height: bounds.size.height).fill()
    }

    func drawPageGuideLineAt(position: CGFloat) {
        NSColor(calibratedRed: 0.863, green: 0.859, blue: 0.863, alpha: 1).set()
        let line = NSBezierPath()
        line.move(to: NSPoint(x: position, y: 0))
        line.line(to: NSPoint(x: position, y: bounds.size.height))
        line.lineWidth = 1
        line.stroke()
    }

    func rectForRange(range: NSRange) -> NSRect {
        var lineRectCount = 0
        let lineRectsForRange = layoutManager!.rectArray(forCharacterRange: range,
                                                         withinSelectedCharacterRange: NSRange(location: NSNotFound, length: 0),
                                                         in: textContainer!,
                                                         rectCount: &lineRectCount)

        if lineRectCount < 1 {
            return .zero
        }
        let y = lineRectsForRange![0].origin.y
        let h = lineRectsForRange![0].size.height
        let w = bounds.size.width
        return NSRect(x: 0, y: y, width: w, height: h).offsetBy(dx: textContainerOrigin.x, dy: textContainerOrigin.y)
    }
}
