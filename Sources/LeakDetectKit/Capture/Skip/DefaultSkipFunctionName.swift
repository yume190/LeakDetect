//
//  File.swift
//  
//
//  Created by Yume on 2022/5/17.
//

import Foundation

let skipFunctionName = [
    // Thread
    "Thread.detachNewThread",
    
    // GCD
    "DispatchQueue.main.async",
    "DispatchQueue.main.asyncAfter",
    
    "UIView.animate",
    
    // Timer
    "Timer.scheduledTimer",
    
    /// Rx
    "Observable.create",
    "Disposables.create",
]
