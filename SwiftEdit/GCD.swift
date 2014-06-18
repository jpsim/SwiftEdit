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
    
    class func timerExec(after: Int,_ closure: () -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, CUnsignedLong(after)), {
            dispatch_async(dispatch_get_main_queue(), {
                closure()
            })
        })
    }
}
