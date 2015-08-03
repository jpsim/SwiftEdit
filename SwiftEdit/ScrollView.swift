//
//  ScrollView.swift
//  SwiftEdit
//
//  Created by Scott Horn on 17/06/2014.
//  Copyright (c) 2014 Scott Horn. All rights reserved.
//

import Cocoa

class ScrollView: NSScrollView {
    override func drawRect(dirtyRect: NSRect) {

        let linen = NSImage(named: "LinenBackgroundPattern")
        NSColor(patternImage: linen!).set()
        NSRectFill(bounds)
        let docView = documentView as! NSView
        let docRect = convertRect(docView.bounds, fromView: docView)
        
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.blackColor()
        shadow.shadowBlurRadius = 5
        shadow.set()
        
        NSColor.whiteColor().set()
        NSRectFill(NSRect(x: 0, y: docRect.origin.y,
            width: docRect.origin.x + docRect.size.width, height: docRect.size.height))
    }    
}
