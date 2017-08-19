//
//  EasyGCDGlobalFunctions.swift
//  Pods
//
//  Created by Meniny on 2017-08-19.
//
//

import Foundation
import Dispatch

/// Execute the closure on a specific dispatch queue
///
/// - Parameters:
///   - queue: A specific dispatch queue, default is main queue
///   - sync: If synchronously, default is NO
///   - closure: A closure without parameters
public func dispatch(queue: DispatchQueue = DispatchQueue.main, sync: Bool = false, _ closure: @escaping EasyGCDVoidClosure) {
    EasyGCD.exectue(EasyGCDDispatch(sync: sync), on: queue, closure: closure)
}

/// Execute the closure on the main queue
///
/// - Parameters:
///   - sync: If synchronously, default is NO
///   - closure: A closure without parameters
public func main(sync: Bool = false, _ closure: @escaping EasyGCDVoidClosure) {
    EasyGCD.exectue(EasyGCDDispatch(sync: sync), on: .main, closure: closure)
}

/// Execute the closure on the global queue
///
/// - Parameters:
///   - sync: If synchronously, default is NO
///   - closure: A closure without parameters
public func global(sync: Bool = false, _ closure: @escaping EasyGCDVoidClosure) {
    EasyGCD.exectue(EasyGCDDispatch(sync: sync), on: .global(), closure: closure)
}


