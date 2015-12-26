//
//  ResultFuture.swift
//  Deferred
//
//  Created by Zachary Waldowski on 12/26/15.
//  Copyright © 2015 Big Nerd Ranch. All rights reserved.
//

#if SWIFT_PACKAGE
import Deferred
import Result
#endif
import Dispatch

extension FutureType where Value: ResultType {

    func uponSuccess(queue: dispatch_queue_t = Self.genericQueue, body: Value.Value -> Void) {
        upon(queue) { result in
            result.analysis(ifSuccess: body, ifFailure: { _ in () })
        }
    }

    func uponFailure(queue: dispatch_queue_t = Self.genericQueue, body: ErrorType -> Void) {
        upon(queue) { result in
            result.analysis(ifSuccess: { _ in () }, ifFailure: body)
        }
    }

}
