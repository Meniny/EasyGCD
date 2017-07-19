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

fileprivate var GetTimeout: (_ time: TimeInterval) -> Int64 = {
    Int64($0 * Double(NSEC_PER_SEC))
}

fileprivate var DispatchTimeCalculate: (_ time: TimeInterval) -> DispatchTime = {
    DispatchTime.now() + Double(GetTimeout($0)) / Double(NSEC_PER_SEC)
}

// MARK: - EasyGCD Main structure

public struct EasyGCD {

    public typealias VoidClosure = (Swift.Void) -> (Swift.Void)
    public typealias ApplyClosure = (Swift.Int) -> (Swift.Void)
    
    fileprivate let currentItem: DispatchWorkItem
    fileprivate init(closure: @escaping EasyGCD.VoidClosure) {
        let item = DispatchWorkItem(flags: DispatchWorkItemFlags.inheritQoS, block: closure)
        currentItem = item
    }
}

// MARK: - EasyGCD.Queue
public extension EasyGCD {
    
    public enum Queue {
        
        public enum Atribute {
            static var concurrent: DispatchQueue.Attributes = DispatchQueue.Attributes.concurrent
            static var serial: DispatchQueue.Attributes = []
        }
        
        public static var main: DispatchQueue {
            return DispatchQueue.main
        }
        
        public static var global: (_ priority: DispatchQoS.QoSClass) -> DispatchQueue = { (priority) in
            return DispatchQueue.global(qos: priority)
        }
        
        public static var custom: (_ identifier: String, _ attributes: DispatchQueue.Attributes) -> DispatchQueue = { (identifier, attributes) in
            return DispatchQueue(label: identifier, attributes: attributes)
        }
        
    }
    
}

public extension EasyGCD {
    
    public static var mainQueue: DispatchQueue {
        return EasyGCD.mainQueue
    }
    
    public static var globalQueue: (_ priority: DispatchQoS.QoSClass) -> DispatchQueue = { (priority) in
        return EasyGCD.Queue.global(priority)
    }
    
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
        public func async(_ queue: DispatchQueue, closure: @escaping EasyGCD.VoidClosure) -> EasyGCD.Group {
            queue.async(group: group) {
                autoreleasepool(invoking: closure)
            }
            return self
        }
        
        public func notify(_ queue: DispatchQueue, closure: @escaping EasyGCD.VoidClosure) {
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
            return group.wait(timeout: DispatchTimeCalculate(timeout))
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
            return semaphore.wait(timeout: DispatchTimeCalculate(timeout))
        }
        
    }
}

// MARK: - Chainable methods
public extension EasyGCD {
    
    // MARK: Static methods
    
    @discardableResult
    public static func async(_ queue: DispatchQueue = .main, closure: @escaping EasyGCD.VoidClosure) -> EasyGCD {
        let dispatch = EasyGCD(closure: closure)
        queue.async(execute: dispatch.currentItem)
        return dispatch
    }
    
    @discardableResult
    public static func sync(_ queue: DispatchQueue = .main, closure: @escaping EasyGCD.VoidClosure) -> EasyGCD {
        let dispatch = EasyGCD(closure: closure)
        queue.sync(execute: dispatch.currentItem)
        return dispatch
    }
    
    @discardableResult
    public static func after(_ dispatchTime: DispatchTime, queue: DispatchQueue = .main, closure: @escaping EasyGCD.VoidClosure) -> EasyGCD {
        let dispatch = EasyGCD(closure: closure)
        queue.asyncAfter(deadline: dispatchTime, execute: dispatch.currentItem)
        return dispatch
    }
    
    @discardableResult
    public static func after(_ time: TimeInterval, queue: DispatchQueue = .main, closure: @escaping EasyGCD.VoidClosure) -> EasyGCD {
        return after(DispatchTimeCalculate(time), queue: queue, closure: closure)
    }
    
    // MARK: Instance methods
    
    @discardableResult
    public func async(_ queue: DispatchQueue = .main, closure: @escaping EasyGCD.VoidClosure) -> EasyGCD {
        return chain(time: nil, queue: queue, closure: closure)
    }
    
    @discardableResult
    public func sync(_ queue: DispatchQueue = .main, closure: @escaping EasyGCD.VoidClosure) -> EasyGCD {
        let syncWrapper: EasyGCD.VoidClosure = {
            queue.sync(execute: closure)
        }
        return chain(time: nil, queue: queue, closure: syncWrapper)
    }
    
    @discardableResult
    public func after(_ dispatchTime: DispatchTime, queue: DispatchQueue = .main, closure: @escaping EasyGCD.VoidClosure) -> EasyGCD {
        return chain(dispatchTime: dispatchTime, queue: queue, closure: closure)
    }
    
    @discardableResult
    public func after(_ time: TimeInterval, queue: DispatchQueue = .main, closure: @escaping EasyGCD.VoidClosure) -> EasyGCD {
        return chain(time: time, queue: queue, closure: closure)
    }
    
    // MARK: Private chaining helper method
    /// Private chaining helper method
    fileprivate func chain(dispatchTime: DispatchTime?, queue: DispatchQueue = .main, closure: @escaping EasyGCD.VoidClosure) -> EasyGCD {
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
    
    fileprivate func chain(time: TimeInterval?, queue: DispatchQueue = .main, closure: @escaping EasyGCD.VoidClosure) -> EasyGCD {
        if let time = time {
            return chain(dispatchTime: DispatchTimeCalculate(time), queue: queue, closure: closure)
        }
        return chain(dispatchTime: nil, queue: queue, closure: closure)
    }
    
}

// MARK: - Non-Chainable Methods
public extension EasyGCD {
    
    public static func barrierAsync(_ queue: DispatchQueue = .main, closure: @escaping EasyGCD.VoidClosure) {
        queue.async(flags: .barrier, execute: closure)
    }
    
    public static func barrierSync(_ queue: DispatchQueue = .main, closure: EasyGCD.VoidClosure) {
        queue.sync(flags: .barrier, execute: closure)
    }
    
    public static func apply(_ iterations: Int, queue: DispatchQueue = .main, closure: @escaping EasyGCD.ApplyClosure) {
        queue.async {
            DispatchQueue.concurrentPerform(iterations: iterations, execute: closure)
        }
    }
    
    public static func time(_ timeout: TimeInterval) -> DispatchTime {
        return DispatchTimeCalculate(timeout)
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
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    public static func once(token: String, closure: EasyGCD.VoidClosure) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        if EasyGCD.onceTracker.contains(token) { return }
        
        EasyGCD.onceTracker.append(token)
        closure()
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
        return currentItem.wait(timeout: DispatchTimeCalculate(timeout))
    }
}

public typealias EasyGCDQueue = EasyGCD.Queue
public typealias EasyGCDGroup = EasyGCD.Group
public typealias EasyGCDSemaphore = EasyGCD.Semaphore