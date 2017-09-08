/*
 The MIT License (MIT)
 
 Copyright (c) 2016 Meniny
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation
import Dispatch

// MARK: - EasyGCD Main structure
public typealias EasyGCDVoidClosure = () -> Swift.Void
public typealias EasyGCDApplyClosure = (Swift.Int) -> Swift.Void

public enum EasyGCDDispatch {
    case synchronously
    case asynchronously
    
    public init(sync: Bool) {
        self = sync ? .synchronously : .asynchronously
    }
}

public struct EasyGCD {

    fileprivate let currentItem: DispatchWorkItem
    
    fileprivate init(closure: @escaping EasyGCDVoidClosure) {
        currentItem = DispatchWorkItem(flags: DispatchWorkItemFlags.inheritQoS, block: closure)
    }
}

public extension EasyGCD {
    public static func timeoutCalculate(_ time: TimeInterval) -> Int64 {
        return Int64(time * Double(NSEC_PER_SEC))
    }
    
    public static func dispatchTimeCalculate(_ time: TimeInterval) -> DispatchTime {
        return DispatchTime.now() + Double(EasyGCD.timeoutCalculate(time)) / Double(NSEC_PER_SEC)
    }
    
    public static func execute(selector: Selector, of target: Any) {
        Timer.scheduledTimer(timeInterval: 0, target: target, selector: selector, userInfo: nil, repeats: false)
    }
}

// MARK: - EasyGCD.Queue
public extension EasyGCD {
    
    public enum Queue {
        
        public enum Atribute {
            static var concurrent: DispatchQueue.Attributes = DispatchQueue.Attributes.concurrent
            static var serial: DispatchQueue.Attributes = []
        }
        
        /// Main Dispatch Queue
        public static var main: DispatchQueue {
            return DispatchQueue.main
        }
        
        /// Global Dispatch Queue with Specific Priority
        public static var global: (_ priority: DispatchQoS.QoSClass) -> DispatchQueue = { (priority) in
            return DispatchQueue.global(qos: priority)
        }
        
        /// Custom Dispatch Queue with Specific Identifier and Attributes
        public static var custom: (_ identifier: String, _ attributes: DispatchQueue.Attributes) -> DispatchQueue = { (identifier, attributes) in
            return DispatchQueue(label: identifier, attributes: attributes)
        }
        
    }
    
}

public extension EasyGCD {
    
    /// Main Dispatch Queue
    public static var mainQueue: DispatchQueue {
        return EasyGCD.mainQueue
    }
    
    /// Global Dispatch Queue with Specific Priority
    public static var globalQueue: (_ priority: DispatchQoS.QoSClass) -> DispatchQueue = { (priority) in
        return EasyGCD.Queue.global(priority)
    }
    
    /// Custom Dispatch Queue with Specific Identifier and Attributes
    public static var customQueue: (_ identifier: String, _ attributes: DispatchQueue.Attributes) -> DispatchQueue = { (identifier, attributes) in
        return EasyGCD.Queue.custom(identifier, attributes)
    }
}

// MARK: - EasyGCD.Group
public extension EasyGCD {
    
    
    public struct Group {
        public let group: DispatchGroup = DispatchGroup()
        private var onceToken: Int32 = 0
        
        public func enter() {
            group.enter()
        }
        
        public func leave() {
            group.leave()
        }
        
        public mutating func enterOnce() {
            enter()
            onceToken = 1
        }
        
        @discardableResult
        public mutating func leaveOnce() -> Bool {
            guard OSAtomicCompareAndSwapInt(1, 0, &onceToken) else { return false }
            leave()
            return true
        }
        
        @discardableResult
        public func async(_ queue: DispatchQueue, closure: @escaping EasyGCDVoidClosure) -> EasyGCD.Group {
            queue.async(group: group) {
                autoreleasepool(invoking: closure)
            }
            return self
        }
        
        public func notify(_ queue: DispatchQueue, closure: @escaping EasyGCDVoidClosure) {
            group.notify(queue: queue) {
                autoreleasepool(invoking: closure)
            }
        }
        
        @discardableResult
        public func wait(_ timeout: DispatchTime = DispatchTime.distantFuture) -> DispatchTimeoutResult {
            return group.wait(timeout: timeout)
        }
        
        @discardableResult
        public func wait(_ timeout: TimeInterval) -> DispatchTimeoutResult {
            return group.wait(timeout: EasyGCD.dispatchTimeCalculate(timeout))
        }
        
    }
    
}

// MARK: - EasyGCD.Semaphore
public extension EasyGCD {
    
    public struct Semaphore {
        private let value: Int
        let semaphore: DispatchSemaphore
        
        init(value: Int = 0) {
            self.value = value
            semaphore = DispatchSemaphore(value: value)
        }
        
        @discardableResult
        public func signal() -> Int {
            return semaphore.signal()
        }
        
        @discardableResult
        public func wait(_ timeout: DispatchTime = DispatchTime.distantFuture) -> DispatchTimeoutResult {
            return semaphore.wait(timeout: timeout)
        }
        
        @discardableResult
        public func wait(_ timeout: TimeInterval) -> DispatchTimeoutResult {
            return semaphore.wait(timeout: EasyGCD.dispatchTimeCalculate(timeout))
        }
        
    }
}

// MARK: - Chainable methods

// MARK: Generic methods
public extension EasyGCD {
    
    /// EasyGCD.executes a block of code
    ///
    /// - Parameters:
    ///   - dispatch: (A)synchronously
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - closure: Code closure
    /// - Returns: `EasyGCD` object
    @discardableResult
    public static func exectue(_ dispatch: EasyGCDDispatch = .asynchronously, on queue: DispatchQueue = .main, closure: @escaping EasyGCDVoidClosure) -> EasyGCD {
        let gcd = EasyGCD(closure: closure)
        if dispatch == .asynchronously {
            queue.async(execute: gcd.currentItem)
        } else {
            queue.sync(execute: gcd.currentItem)
        }
        return gcd
    }
}

// MARK: Static methods
public extension EasyGCD {
    
    /// EasyGCD.executes a block of code asynchronously
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - closure: Code closure
    /// - Returns: `EasyGCD` object
    @discardableResult
    public static func async(_ queue: DispatchQueue = .main, closure: @escaping EasyGCDVoidClosure) -> EasyGCD {
        let dispatch = EasyGCD(closure: closure)
        queue.async(execute: dispatch.currentItem)
        return dispatch
    }
    
    /// Perform a `Selector` asynchronously
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - target: Target of `Selector`
    ///   - selector: A `Selector` object
    /// - Returns: `EasyGCD` object
    @discardableResult
    public static func async(_ queue: DispatchQueue = .main, target: Any, selector: Selector) -> EasyGCD {
        let dispatch = EasyGCD {
            EasyGCD.execute(selector: selector, of: target)
        }
        queue.async(execute: dispatch.currentItem)
        return dispatch
    }
    
    /// EasyGCD.executes a block of code synchronously
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - closure: Code closure
    /// - Returns: `EasyGCD` object
    @discardableResult
    public static func sync(_ queue: DispatchQueue = .main, closure: @escaping EasyGCDVoidClosure) -> EasyGCD {
        let dispatch = EasyGCD(closure: closure)
        queue.sync(execute: dispatch.currentItem)
        return dispatch
    }
    
    /// Perform a `Selector` synchronously
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - target: Target of `Selector`
    ///   - selector: A `Selector` object
    /// - Returns: `EasyGCD` object
    @discardableResult
    public static func sync(_ queue: DispatchQueue = .main, target: Any, selector: Selector) -> EasyGCD {
        let dispatch = EasyGCD {
            EasyGCD.execute(selector: selector, of: target)
        }
        queue.sync(execute: dispatch.currentItem)
        return dispatch
    }
    
    /// EasyGCD.executes a block of code asynchronously after a specific time interval
    ///
    /// - Parameters:
    ///   - dispatchTime: `DispatchTime` object
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - closure: Code closure
    /// - Returns: `EasyGCD` object
    @discardableResult
    public static func after(_ dispatchTime: DispatchTime, queue: DispatchQueue = .main, closure: @escaping EasyGCDVoidClosure) -> EasyGCD {
        let dispatch = EasyGCD(closure: closure)
        queue.asyncAfter(deadline: dispatchTime, execute: dispatch.currentItem)
        return dispatch
    }
    
    /// Perform a `Selector` asynchronously after a specific time interval
    ///
    /// - Parameters:
    ///   - dispatchTime: `DispatchTime` object
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - target: Target of `Selector`
    ///   - selector: A `Selector` object
    /// - Returns: `EasyGCD` object
    @discardableResult
    public static func after(_ dispatchTime: DispatchTime, queue: DispatchQueue = .main, target: Any, selector: Selector) -> EasyGCD {
        let asyncWrapper: EasyGCDVoidClosure = {
            queue.async(execute: {
                EasyGCD.execute(selector: selector, of: target)
            })
        }
        return after(dispatchTime, queue: queue, closure: asyncWrapper)
    }
    
    /// EasyGCD.executes a block of code asynchronously after a specific time interval
    ///
    /// - Parameters:
    ///   - time: `TimeInterval` object
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - closure: Code closure
    /// - Returns: `EasyGCD` object
    @discardableResult
    public static func after(_ time: TimeInterval, queue: DispatchQueue = .main, closure: @escaping EasyGCDVoidClosure) -> EasyGCD {
        return after(EasyGCD.dispatchTimeCalculate(time), queue: queue, closure: closure)
    }
    
    /// Perform a `Selector` asynchronously after a specific time interval
    ///
    /// - Parameters:
    ///   - time: `TimeInterval` object
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - target: Target of `Selector`
    ///   - selector: A `Selector` object
    /// - Returns: `EasyGCD` object
    @discardableResult
    public static func after(_ time: TimeInterval, queue: DispatchQueue = .main, target: Any, selector: Selector) -> EasyGCD {
        let asyncWrapper: EasyGCDVoidClosure = {
            queue.async(execute: {
                EasyGCD.execute(selector: selector, of: target)
            })
        }
        return after(EasyGCD.dispatchTimeCalculate(time), queue: queue, closure: asyncWrapper)
    }
    
}

// MARK: Instance methods
internal extension EasyGCD {
    
    /// EasyGCD.executes a block of code asynchronously
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - closure: Code closure
    /// - Returns: `EasyGCD` object
    @discardableResult
    internal func async(_ queue: DispatchQueue = .main, closure: @escaping EasyGCDVoidClosure) -> EasyGCD {
        return chain(time: nil, queue: queue, closure: closure)
    }
    
    /// Perform a `Selector` asynchronously
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - target: Target of `Selector`
    ///   - selector: A `Selector` object
    /// - Returns: `EasyGCD` object
    @discardableResult
    internal func async(_ queue: DispatchQueue = .main, target: Any, selector: Selector) -> EasyGCD {
        let asyncWrapper: EasyGCDVoidClosure = {
            queue.async(execute: {
                EasyGCD.execute(selector: selector, of: target)
            })
        }
        return chain(time: nil, queue: queue, closure: asyncWrapper)
    }
    
    /// EasyGCD.executes a block of code synchronously
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - closure: Code closure
    /// - Returns: `EasyGCD` object
    @discardableResult
    internal func sync(_ queue: DispatchQueue = .main, closure: @escaping EasyGCDVoidClosure) -> EasyGCD {
        let syncWrapper: EasyGCDVoidClosure = {
            queue.sync(execute: closure)
        }
        return chain(time: nil, queue: queue, closure: syncWrapper)
    }
    
    /// Perform a `Selector` synchronously
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - target: Target of `Selector`
    ///   - selector: A `Selector` object
    /// - Returns: `EasyGCD` object
    @discardableResult
    internal func sync(_ queue: DispatchQueue = .main, target: Any, selector: Selector) -> EasyGCD {
        let syncWrapper: EasyGCDVoidClosure = {
            queue.sync(execute: { 
                EasyGCD.execute(selector: selector, of: target)
            })
        }
        return chain(time: nil, queue: queue, closure: syncWrapper)
    }
    
    /// EasyGCD.executes a block of code asynchronously after a specific time interval
    ///
    /// - Parameters:
    ///   - dispatchTime: `DispatchTime` object
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - closure: Code closure
    /// - Returns: `EasyGCD` object
    @discardableResult
    internal func after(_ dispatchTime: DispatchTime, queue: DispatchQueue = .main, closure: @escaping EasyGCDVoidClosure) -> EasyGCD {
        return chain(dispatchTime: dispatchTime, queue: queue, closure: closure)
    }
    
    /// Perform a `Selector` asynchronously after a specific time interval
    ///
    /// - Parameters:
    ///   - time: `DispatchTime` object
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - target: Target of `Selector`
    ///   - selector: A `Selector` object
    /// - Returns: `EasyGCD` object
    @discardableResult
    internal func after(_ dispatchTime: DispatchTime, queue: DispatchQueue = .main, target: Any, selector: Selector) -> EasyGCD {
        let asyncWrapper: EasyGCDVoidClosure = {
            queue.async(execute: {
                EasyGCD.execute(selector: selector, of: target)
            })
        }
        return chain(dispatchTime: dispatchTime, queue: queue, closure: asyncWrapper)
    }
    
    /// EasyGCD.executes a block of code asynchronously after a specific time interval
    ///
    /// - Parameters:
    ///   - dispatchTime: `TimeInterval` object
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - closure: Code closure
    /// - Returns: `EasyGCD` object
    @discardableResult
    internal func after(_ time: TimeInterval, queue: DispatchQueue = .main, closure: @escaping EasyGCDVoidClosure) -> EasyGCD {
        return chain(time: time, queue: queue, closure: closure)
    }
    
    /// Perform a `Selector` asynchronously after a specific time interval
    ///
    /// - Parameters:
    ///   - time: `TimeInterval` object
    ///   - queue: `DispatchQueue` object, degault is `.main`
    ///   - target: Target of `Selector`
    ///   - selector: A `Selector` object
    /// - Returns: `EasyGCD` object
    @discardableResult
    internal func after(_ time: TimeInterval, queue: DispatchQueue = .main, target: Any, selector: Selector) -> EasyGCD {
        let asyncWrapper: EasyGCDVoidClosure = {
            queue.async(execute: {
                EasyGCD.execute(selector: selector, of: target)
            })
        }
        return chain(time: time, queue: queue, closure: asyncWrapper)
    }
}

// MARK: - Private chaining helper method
fileprivate extension EasyGCD {
    
    fileprivate func chain(dispatchTime: DispatchTime?, queue: DispatchQueue = .main, closure: @escaping EasyGCDVoidClosure) -> EasyGCD {
        let newDispatch = EasyGCD(closure: closure)
        let nextItem: DispatchWorkItem
        if let time = dispatchTime {
            nextItem = DispatchWorkItem(flags: .inheritQoS) {
                queue.asyncAfter(deadline: time, execute: newDispatch.currentItem)
            }
        } else {
            nextItem = newDispatch.currentItem
        }
        currentItem.notify(queue: queue, execute: nextItem)
        return newDispatch
    }
    
    fileprivate func chain(time: TimeInterval?, queue: DispatchQueue = .main, closure: @escaping EasyGCDVoidClosure) -> EasyGCD {
        if let time = time {
            return chain(dispatchTime: EasyGCD.dispatchTimeCalculate(time), queue: queue, closure: closure)
        }
        return chain(dispatchTime: nil, queue: queue, closure: closure)
    }
    
}

// MARK: - Non-Chainable Methods
public extension EasyGCD {
    
    public static func barrierAsync(_ queue: DispatchQueue = .main, closure: @escaping EasyGCDVoidClosure) {
        queue.async(flags: .barrier, execute: closure)
    }
    
    public static func barrierSync(_ queue: DispatchQueue = .main, closure: EasyGCDVoidClosure) {
        queue.sync(flags: .barrier, execute: closure)
    }
    
    public static func apply(_ iterations: Int, queue: DispatchQueue = .main, closure: @escaping EasyGCDApplyClosure) {
        queue.async {
            DispatchQueue.concurrentPerform(iterations: iterations, execute: closure)
        }
    }
    
    public static func time(_ timeout: TimeInterval) -> DispatchTime {
        return EasyGCD.dispatchTimeCalculate(timeout)
    }
    
    public static var group: EasyGCD.Group {
        return EasyGCD.Group()
    }
    
    public static func semaphore(_ value: Int = 0) -> EasyGCD.Semaphore {
        return EasyGCD.Semaphore(value: value)
    }
    
}

// MARK: - Once
public extension EasyGCD {
        
    private static var onceTracker: [String] = []
    
    /**
     EasyGCD.executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only EasyGCD.execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter closure: Closure to EasyGCD.execute once
     - Returns: If `closure` will be executed
     */
    @discardableResult
    public static func once(token: String, closure: EasyGCDVoidClosure) -> Bool {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        if EasyGCD.onceTracker.contains(token) {
            return false
        }
        
        EasyGCD.onceTracker.append(token)
        closure()
        return true
    }
    
    /**
     EasyGCD.executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only EasyGCD.execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter target: Target
     - parameter selector: `Selector`
     */
    public static func once(token: String, target: Any, selector: Selector) {
        EasyGCD.once(token: token) { 
            EasyGCD.execute(selector: selector, of: target)
        }
    }
}

// MARK: - Block methods
public extension EasyGCD {
    
    public func cancel() {
        currentItem.cancel()
    }
    
    @discardableResult
    public func wait(_ timeout: DispatchTime = DispatchTime.distantFuture) -> DispatchTimeoutResult {
        return currentItem.wait(timeout: timeout)
    }
    
    @discardableResult
    public func wait(_ timeout: TimeInterval) -> DispatchTimeoutResult {
        return currentItem.wait(timeout: EasyGCD.dispatchTimeCalculate(timeout))
    }
}

