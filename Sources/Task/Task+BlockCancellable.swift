//
//  Task+BlockCancellable.swift
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

    public init(upon queue: dispatch_queue_t, flags: dispatch_block_flags_t = dispatch_block_flags_t(0), @autoclosure(escaping) onCancel produceError: () -> ErrorType, body: () throws -> T) {
        let deferred = Deferred<Result<T>>()

        let block = dispatch_block_create(flags) {
            deferred.fill(Result(with: body))
        }

        defer {
            dispatch_async(queue, block)
        }

        dispatch_block_notify(block, queue) {
            guard dispatch_block_testcancel(block) != 0 else { return }
            let error = produceError()
            deferred.fill(.Failure(error))
        }

        self.init(deferred) {
            dispatch_block_cancel(block)
        }
    }

}
