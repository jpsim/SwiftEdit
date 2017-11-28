//
//  AppDelegate.swift
//  SwiftEdit
//
//  Created by Scott Horn on 14/06/2014.
//  Copyright (c) 2014 Scott Horn. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow?
    @IBOutlet var scrollView: NSScrollView?
    var textView: NSTextView { return scrollView!.contentView.documentView as! NSTextView }
    var rulerView: RulerView?
    var syntaxHighligher: SwiftSyntaxHighligher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let textView = self.textView
        textView.textContainerInset = NSSize(width: 0, height: 1)
        textView.font = NSFont.userFixedPitchFont(ofSize: NSFont.smallSystemFontSize)
        textView.isAutomaticQuoteSubstitutionEnabled = false

        rulerView = RulerView(scrollView: scrollView, orientation: .verticalRuler)
        scrollView?.verticalRulerView = rulerView
        scrollView?.hasHorizontalRuler = false
        scrollView?.hasVerticalRuler = true
        scrollView?.rulersVisible = true

        syntaxHighligher = SwiftSyntaxHighligher(textStorage: textView.textStorage!, textView: textView, scrollView: scrollView!)
    }
}
