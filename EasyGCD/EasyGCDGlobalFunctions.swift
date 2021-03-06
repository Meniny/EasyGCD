//
//  EasyGCDGlobalFunctions.swift
//  Pods
//
//  Created by Meniny on 2017-08-19.
//
//

import Foundation
import Dispatch

/*
public var synchronously: Bool {
    return true
}

public var asynchronously: Bool {
    return false
}
*/

/// Execute the closure on a specific dispatch queue
///
/// - Parameters:
///   - queue: A specific dispatch queue
///   - policy: The dispatch policy, default is asynchronously
///   - closure: A closure without parameters
public func dispatch(_ queue: DispatchQueue, _ policy: EasyGCDDispatch = .asynchronously, _ closure: @escaping EasyGCDVoidClosure) {
    EasyGCD.exectue(policy, on: queue, closure: closure)
}

/// Execute the closure on the main queue
///
/// - Parameters:
///   - policy: The dispatch policy, default is asynchronously
///   - closure: A closure without parameters
public func main(_ policy: EasyGCDDispatch = .asynchronously, _ closure: @escaping EasyGCDVoidClosure) {
    EasyGCD.exectue(policy, on: .main, closure: closure)
}

/// Execute the closure on the global queue
///
/// - Parameters:
///   - policy: The dispatch policy, default is asynchronously
///   - closure: A closure without parameters
public func global(_ policy: EasyGCDDispatch = .asynchronously, _ closure: @escaping EasyGCDVoidClosure) {
    EasyGCD.exectue(policy, on: .global(), closure: closure)
}

/// Execute the closure on after a specific time interval
///
/// - Parameters:
///   - time: A time interval
///   - closure: A closure without parameters
public func after(_ time: TimeInterval, _ closure: @escaping EasyGCDVoidClosure) {
    EasyGCD.after(time, closure: closure)
}

/// Execute the closure only once
///
/// - Parameters:
///   - token: A once token string
///   - closure: A closure without parameters
/// - Returns: If `closure` will be executed
@discardableResult
public func once(_ token: String, _ closure: @escaping EasyGCDVoidClosure) -> Bool {
    return EasyGCD.once(token: token, closure: closure)
}

/// Execute the closure on a specific dispatch queue synchronously
///
/// - Parameters:
///   - queue: A specific dispatch queue, default is global queue
///   - closure: A closure without parameters
public func sync(_ queue: DispatchQueue = .global(), _ closure: @escaping EasyGCDVoidClosure) {
    EasyGCD.sync(queue, closure: closure)
}

/// Execute the closure on a specific dispatch queue asynchronously
///
/// - Parameters:
///   - queue: A specific dispatch queue, default is main queue
///   - closure: A closure without parameters
public func async(_ queue: DispatchQueue = .main, _ closure: @escaping EasyGCDVoidClosure) {
    EasyGCD.async(queue, closure: closure)
}




