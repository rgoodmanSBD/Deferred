//
//  ResultPromise.swift
//  Deferred
//
//  Created by Zachary Waldowski on 10/27/15.
//  Copyright © 2014-2015 Big Nerd Ranch. Licensed under MIT.
//

#if SWIFT_PACKAGE
import Deferred
import Result
#endif
import Dispatch

extension PromiseType where Value: ResultType {

    func succeed(value: Value.Value) -> Bool {
        return fill(Value(value: value))
    }

    func fail(error: ErrorType) -> Bool {
        return fill(Value(error: error))
    }

    func fill(@noescape with body: () throws -> Value.Value) -> Bool {
        do {
            return try succeed(body())
        } catch {
            return fail(error)
        }
    }

    init(@noescape with body: () throws -> Value.Value) {
        self.init()
        fill(with: body)
    }

}
