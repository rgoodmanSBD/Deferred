//
//  IgnoringTask.swift
//  Deferred
//
//  Created by Zachary Waldowski on 12/30/15.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

#if SWIFT_PACKAGE
import Deferred
import Result
#endif
import Dispatch

private extension ResultType {
    var ignored: Result<Void> {
        return analysis(ifSuccess: { _ in .Success() }, ifFailure: Result.Failure)
    }
}

public struct IgnoringTask<Value> {
    private let task: Future<Result<Value>>
    private let cancellation: Cancellation

    public init(task: Future<Result<Value>>, cancellation: Cancellation) {
        self.task = task
        self.cancellation = cancellation
    }
}

extension IgnoringTask {
    /// Attempt to cancel the underlying task. This is a "best effort"; there are several
    /// situations in which cancellation will not happen:
    ///
    /// * The task has already completed (racing with isFilled).
    /// * The underlying task has entered an uncancelable state.
    /// * The underlying task is not cancelable.
    public func cancel() {
        cancellation()
    }
}

extension IgnoringTask: FutureType {
    /// Call some function once the event completes.
    ///
    /// If the event is already completed, the function will be submitted to the
    /// queue immediately. An `upon` call is always execute asynchronously.
    ///
    /// - parameter queue: A dispatch queue for executing the given function on.
    public func upon(queue: dispatch_queue_t, body: Result<Void> -> Void) {
        return task.upon(queue) { body($0.ignored) }
    }

    /// Waits synchronously for the event to complete.
    ///
    /// If the event is already completed, the call returns immediately.
    ///
    /// - parameter time: A length of time to wait for event to complete.
    /// - returns: Nothing, if filled within the timeout, or `nil`.
    public func wait(time: Timeout) -> Result<Void>? {
        return task.wait(time).map { $0.ignored }
    }
}

extension IgnoringTask {
    public init(task other: IgnoringTask<Value>) {
        self.init(task: other.task, cancellation: other.cancellation)
    }

    public init<Other: FutureType where Other.Value: ResultType, Other.Value.Value == Value>(_ other: Other, cancellation: Cancellation) {
        self.init(task: Future(other), cancellation: cancellation)
    }
}
