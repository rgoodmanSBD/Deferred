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

extension DispatchBlock: Cancellable { }

extension Task {

    public convenience init(queue: dispatch_queue_t, flags: dispatch_block_flags_t, function: () -> Result<T, Error>, @autoclosure(escaping) produceError: () -> Error) {
        self.init()

        let block = DispatchBlock(flags: flags) {
            let result = function()
            self.fillIfUnfilled(result)
        }

        block.upon(queue, flags: []) { [unowned self] in
            let error = produceError()
            self.fillIfUnfilled(.Failure(error))
        }

        task = block

        block.callUponQueue(queue)
    }

}
