//
//  Task+Cancellable.swift
//  Deferred
//
//  Created by Zachary Waldowski on 7/14/15.
//  Copyright © 2014-2015 Big Nerd Ranch. Licensed under MIT.
//

#if SWIFT_PACKAGE
import Deferred
import Result
#endif
import Dispatch

extension Task {

    public convenience init(queue: dispatch_queue_t, flags: dispatch_block_flags_t, function: () -> Result<T, Error>, @autoclosure(escaping) produceError: () -> Error) {
        let deferred = Deferred<Result<T, Error>>()

        let block = dispatch_block_create(flags) {
            let result = function()
            _ = try? deferred.fill(result)
        }

        defer {
            dispatch_async(queue, block)
        }

        dispatch_block_notify(block, queue) {
            guard dispatch_block_testcancel(block) != 0 else { return }
            let error = produceError()
            _ = try? deferred.fill(.Failure(error))
        }

        self.init(deferred) {
            dispatch_block_cancel(block)
        }
    }

}
