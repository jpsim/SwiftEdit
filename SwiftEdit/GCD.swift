//
//  GCD.swift
//  SwiftEdit
//
//  Created by Scott Horn on 18/06/2014.
//  Copyright (c) 2014 Scott Horn. All rights reserved.
//

import Cocoa

class GCD {
    class func asyncExec(closure: () -> ()) {
        timerExec(0, closure)
    }
    
    class func timerExec(after: Double,_ closure: () -> ()) {
        let delay = after * Double(NSEC_PER_MSEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            closure()
        }
    }
}
