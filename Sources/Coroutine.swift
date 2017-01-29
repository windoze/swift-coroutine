//
//  coroutine.swift
//
//  Created by Chen Xu on 2017-1-29.
//  Copyright (c) 2017 0d0a.com. All rights reserved.
//

import Context

// HACK: Type eraser
protocol Startable : AnyObject {
    func start()
}

/**
 * Coroutine iterator, support for loop
 */
public struct CoroutineIterator<Element> : IteratorProtocol {
    var owner: Coroutine<Element>
    init(owner: Coroutine<Element>) {
        self.owner=owner
    }
    public func next()->Element? {
        return owner.next()
    }
}

/**
 * Coroutine
 */
public class Coroutine<UpType>: Startable, Sequence {
    public typealias Element = UpType
    public typealias Iterator = CoroutineIterator<Element>
    
    var stack: coro_stack
    var caller_ctx: coro_context
    var coro_ctx: coro_context
    var entry: (_:(UpType)->()) -> ()
    var completed:Bool
    var upValue: UpType?
    
    func start() {
        // Now we're in callee context
        self.entry({ (up:UpType)->() in
            self.upValue=up
            coro_transfer(&self.coro_ctx, &self.caller_ctx)
        })
        completed=true
        // Switch back to caller
        coro_transfer(&self.coro_ctx, &self.caller_ctx)
    }
    
    /**
     * Called from caller context, continues the coroutine
     * Returns an upValue set by yield called by coroutine
     */
    public func next()->UpType? {
        if(!completed) {
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
     * Create a coroutine, supply a callback function acts as "yield"
     * Coroutine calls the callback to yield an upValue
     */
    public init(entry:@escaping (_:(UpType)->())->Void, withSuggestedStackSize:UInt32 = 0) {
        stack=coro_stack()
        coro_stack_alloc(&stack, withSuggestedStackSize)
        caller_ctx=coro_context()
        coro_ctx=coro_context()
        self.entry=entry
        completed=false
        coro_create(&coro_ctx,
                    { (ptr:UnsafeMutableRawPointer?) -> () in
                        // HACK: Swift doesn't allow C routine calls back to a generic closure
                        // Use protocol Startable as a type eraser
                        (Unmanaged<AnyObject>.fromOpaque(ptr!).takeRetainedValue() as! Startable).start()
                    },
                    Unmanaged.passUnretained(self).toOpaque(), stack.sptr, stack.ssze)
    }
    
    deinit {
        coro_stack_free(&stack)
    }
}
