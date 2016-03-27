//
//  TaskCollections.swift
//  Deferred
//
//  Created by Zachary Waldowski on 11/18/15.
//  Copyright © 2014-2015 Big Nerd Ranch. Licensed under MIT.
//

#if SWIFT_PACKAGE
import Deferred
import Result
#endif
import Darwin

public extension CollectionType where Generator.Element: FutureType, Generator.Element.Value: ResultType {

    var allTasks: Task<Void> {
        if isEmpty {
            return Task(value: .Success())
        }

        let incomingTasks = Array(self)
        var completedTaskCount: Int64 = 0
        let coalescingDeferred = Deferred<Result<Void>>()

        for task in incomingTasks {
            task.upon { result in
                result.analysis(ifSuccess: { _ in
                    guard OSAtomicIncrement64(&completedTaskCount) == numericCast(incomingTasks.count) else {
                        return
                    }
                    _ = coalescingDeferred.fill(.Success())
                }, ifFailure: { error in
                    _ = coalescingDeferred.fill(.Failure(error))
                })
            }
        }

        return Task(coalescingDeferred, cancellation: { _ in })
    }

}
