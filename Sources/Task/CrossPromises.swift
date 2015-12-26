//
//  CrossFutures.swift
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

extension PromiseType {

    init<Other: FutureType where Other.Value == Value>(_ other: Other) {
        self.init()
        other.upon {
            self.fill($0)
        }
    }

    init(@noescape with body: () -> Value) {
        self.init()
        fill(body())
    }

}

extension PromiseType where Value: ResultType {

    init(@noescape with body: () throws -> Value.Value) {
        self.init()
        let result = Value(with: body)
        fill(result)
    }

}
