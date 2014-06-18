//
//  GroovySyntaxHighligher.swift
//  SwiftEdit
//
//  Created by Scott Horn on 18/06/2014.
//  Copyright (c) 2014 Scott Horn. All rights reserved.
//

import Cocoa

let GROOVY_ELEMENT_TYPE_KEY = "groovyElementType"

class GroovySyntaxHighligher: NSObject, NSTextStorageDelegate, NSLayoutManagerDelegate {
    var textStorage : NSTextStorage?
    let groovyStyles = [
        "COMMENT": NSColor.grayColor(),
        "QUOTES": NSColor.magentaColor(),
        "SINGLES_QUOTES": NSColor.greenColor(),
        "SLASHY_QUOTES": NSColor.orangeColor(),
        "DIGIT": NSColor.redColor(),
        "OPERATION": NSColor.purpleColor(),
        "RESERVED_WORDS": NSColor.blueColor()
    ]
    let reservedWords = [
        "(?:\\babstract\\b)",
        "(?:\\bassert\\b)",
        "(?:\\bdefault\\b)",
        "(?:\\bif\\b)",
        "(?:\\bprivate\\b)",
        "(?:\\bthis\\b)",
        "(?:\\bboolean\\b)",
        "(?:\\bdo\\b)",
        "(?:\\bimplements\\b)",
        "(?:\\bprotected\\b)",
        "(?:\\bthrow\\b)",
        "(?:\\bbreak\\b)",
        "(?:\\bdouble\\b)",
        "(?:\\bimport\\b)",
        "(?:\\bpublic\\b)",
        "(?:\\bthrows\\b)",
        "(?:\\bbyte\\b)",
        "(?:\\belse\\b)",
        "(?:\\binstanceof\\b)",
        "(?:\\breturn\\b)",
        "(?:\\btransient\\b)",
        "(?:\\bcase\\b)",
        "(?:\\bextends\\b)",
        "(?:\\bint\\b)",
        "(?:\\bshort\\b)",
        "(?:\\btry\\b)",
        "(?:\\bcatch\\b)",
        "(?:\\bfinal\\b)",
        "(?:\\binterface\\b)",
        "(?:\\benum\\b)",
        "(?:\\bstatic\\b)",
        "(?:\\bvoid\\b)",
        "(?:\\bchar\\b)",
        "(?:\\bfinally\\b)",
        "(?:\\blong\\b)",
        "(?:\\bstrictfp\\b)",
        "(?:\\bvolatile\\b)",
        "(?:\\bclass\\b)",
        "(?:\\bfloat\\b)",
        "(?:\\bnative\\b)",
        "(?:\\bsuper\\b)",
        "(?:\\bwhile\\b)",
        "(?:\\bconst\\b)",
        "(?:\\bfor\\b)",
        "(?:\\bnew\\b)",
        "(?:\\bswitch\\b)",
        "(?:\\bcontinue\\b)",
        "(?:\\bgoto\\b)",
        "(?:\\bpackage\\b)",
        "(?:\\bdef\\b)",
        "(?:\\bas\\b)",
        "(?:\\bin\\b)",
        "(?:\\bsynchronized\\b)",
        "(?:\\bnull\\b)"
    ];
    var matchers: String[]
    var regex : NSRegularExpression
    var textView : NSTextView?
    var scrollView: NSScrollView?
    
    init() {
        matchers = [
            "COMMENT", "/\\*(?s:.)*?(?:\\*/|\\z)",
            "COMMENT", "//.*",
            "QUOTES",  "(?ms:\"{3}(?!\\\"{1,3}).*?(?:\"{3}|\\z))|(?:\"{1}(?!\\\").*?(?:\"|\\Z))",
            "SINGLE_QUOTES", "(?ms:'{3}(?!'{1,3}).*?(?:'{3}|\\z))|(?:'[^'].*?(?:'|\\z))",
            "DIGIT", "(?<=\\b)(?:0x)?\\d+[efld]?",
            "OPERATION", "[\\w\\$&&[\\D]][\\w\\$]* *\\(",
            "RESERVED_WORDS", join("|", reservedWords)
        ]
        
        var regExItems: String[] = []
        for (idx, item) in enumerate(matchers) {
            if idx % 2 == 1 {
                regExItems.append(item)
            }
        }
        let regExString = "(" + join(")|(", regExItems) + ")"
        regex = NSRegularExpression(pattern: regExString, options: nil, error: nil)
    }
    
    convenience init(textStorage: NSTextStorage, textView: NSTextView, scrollView: NSScrollView) {
        self.init()
        self.textStorage = textStorage
        self.scrollView = scrollView
        self.textView = textView
        
        textStorage.delegate = self
        scrollView.contentView.postsBoundsChangedNotifications = true
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "textStorageDidProcessEditing:",
            name: NSViewBoundsDidChangeNotification,
            object: scrollView.contentView)
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
        let range = visibleRange()
        let string = textStorage!.string
        let layoutManagerList = textStorage!.layoutManagers as NSLayoutManager[]
        for layoutManager in layoutManagerList {
            layoutManager.delegate = self
            layoutManager.removeTemporaryAttribute(GROOVY_ELEMENT_TYPE_KEY,
                forCharacterRange: range)
        }
        regex.enumerateMatchesInString(string,
            options: nil, range: range, usingBlock: {
            (match, flags, stop) in
                for var matchIndex = 1; matchIndex < match.numberOfRanges; ++matchIndex {
                    let matchRange = match.rangeAtIndex(matchIndex)
                    if matchRange.location == NSNotFound {
                        continue
                    }
                    for layoutManager in layoutManagerList {
                        layoutManager.addTemporaryAttributes([GROOVY_ELEMENT_TYPE_KEY: self.matchers[(matchIndex - 1) * 2]],
                            forCharacterRange: matchRange)
                    }
                }
        })
    }
    
    func textStorageDidProcessEditing(aNotification: NSNotification) {
        GCD.asyncExec {
            self.parse(self)
        }
    }
    
    func layoutManager(layoutManager: NSLayoutManager!, shouldUseTemporaryAttributes attrs: NSDictionary!, forDrawingToScreen toScreen: Bool, atCharacterIndex charIndex: Int, effectiveRange effectiveCharRange: CMutablePointer<NSRange>) -> NSDictionary! {
        
        if toScreen {
            if let type = attrs[GROOVY_ELEMENT_TYPE_KEY] as? String {
                if let style = groovyStyles[type] {
                    return [NSForegroundColorAttributeName:style]
                }
            }
        }
        return attrs
    }

}
