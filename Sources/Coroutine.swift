//
//  coroutine.swift
//
//  Created by Chen Xu on 2017-1-29.
//  Copyright (c) 2017 0d0a.com. All rights reserved.
//

import Context

// HACK: Type eraser

protocol Startable: AnyObject {
    func start()
}

/**
 * Coroutine iterator, support for loop
 */

public struct CoroutineIterator<Element>: IteratorProtocol {
    var owner: CoroutineSequence<Element>
    init(owner: CoroutineSequence<Element>) {
        self.owner = owner
    }

    public func next() -> Element? {
        return owner.next()
    }
}

/**
 * CoroutineSequence
 * Every time a new value is yielded from coroutine when calling next()
 */

public class CoroutineSequence<Element>: Startable, Sequence {
    public typealias Iterator = CoroutineIterator<Element>

    var stack: coro_stack
    var caller_ctx: coro_context
    var coro_ctx: coro_context
    var entry: (_: (Element) -> Void) -> Void
    var completed: Bool
    var upValue: Element?

    func start() {
        // Now we're in callee context
        self.entry({ (up: Element) -> Void in
            self.upValue = up
            coro_transfer(&self.coro_ctx, &self.caller_ctx)
        })
        completed = true
        // Switch back to caller
        coro_transfer(&self.coro_ctx, &self.caller_ctx)
    }

    /**
     * Called from caller context, continues the coroutine
     * Returns an upValue set by yield called by coroutine
     */
    public func next() -> Element? {
        if (!completed) {
            self.upValue = Optional.none
            coro_transfer(&self.caller_ctx, &self.coro_ctx)
        }
        return self.upValue
    }

    /**
     * Conform to Sequence protocol 
     */
    public func makeIterator() -> Iterator {
        return CoroutineIterator(owner: self)
    }

    /**
     * Create a coroutine sequence, supply a callback function acts as "yield"
     * Coroutine calls the callback to yield an upValue to feed the sequence
     */
    public init(entry: @escaping (_: (Element) -> Void) -> Void, withSuggestedStackSize: Int = 0) {
        stack = coro_stack()
        coro_stack_alloc(&stack, withSuggestedStackSize)
        caller_ctx = coro_context()
        coro_ctx = coro_context()
        self.entry = entry
        completed = false
        coro_create(&coro_ctx,
                { (ptr: UnsafeMutableRawPointer?) -> Void in
                    // HACK: Swift doesn't allow C routine calls back to a generic closure
                    // Use protocol Startable as a type eraser
                    (Unmanaged<AnyObject>.fromOpaque(ptr!).autorelease().takeRetainedValue() as! Startable).start()
                },
                Unmanaged.passUnretained(self).toOpaque(), stack.sptr, stack.ssze)
    }

    deinit {
        coro_stack_free(&stack)
    }
}

/**
 * Asymmetric coroutine with separated Up and Down types
 */

public class Coroutine<UpType, DownType>: Startable {
    var stack: coro_stack
    var caller_ctx: coro_context
    var coro_ctx: coro_context
    var entry: (DownType, _: (UpType) -> DownType) -> Void
    var completed: Bool
    var upValue: UpType?
    var downValue: DownType?

    func start() {
        // Now we're in callee context
        // Invoke entry with the first down value
        self.entry(downValue!, { (up: UpType) -> DownType in
            self.upValue = up
            self.downValue = Optional.none
            coro_transfer(&self.coro_ctx, &self.caller_ctx)
            return downValue!
        })
        completed = true
        // Switch back to caller
        coro_transfer(&self.coro_ctx, &self.caller_ctx)
    }

    /**
     * Called from caller context, continues the coroutine, pass down value to corotine
     * This passed down value will be the argument of entry function in first time that 
     * this method is called, or be the return value of yield called within coroutine
     * Returns an upValue set by yield called by coroutine
     */
    public func next(withValue: DownType) -> UpType? {
        if (!completed) {
            self.downValue = withValue
            self.upValue = Optional.none
            coro_transfer(&self.caller_ctx, &self.coro_ctx)
        }
        return self.upValue
    }

    /**
     * Create a coroutine, supply a callback function acts as "yield"
     * Coroutine calls the callback to yield an upValue
     */
    public init(entry: @escaping (DownType, _: (UpType) -> DownType) -> Void, withSuggestedStackSize: Int = 0) {
        stack = coro_stack()
        coro_stack_alloc(&stack, withSuggestedStackSize)
        caller_ctx = coro_context()
        coro_ctx = coro_context()
        self.entry = entry
        completed = false
        coro_create(&coro_ctx,
                { (ptr: UnsafeMutableRawPointer?) -> Void in
                    // HACK: Swift doesn't allow C routine calls back to a generic closure
                    // Use protocol Startable as a type eraser
                    (Unmanaged<AnyObject>.fromOpaque(ptr!).autorelease().takeRetainedValue() as! Startable).start()
                },
                Unmanaged.passUnretained(self).toOpaque(), stack.sptr, stack.ssze)
    }

    deinit {
        coro_stack_free(&stack)
    }
}
