//
//  Task.swift
//  Deferred
//
//  Created by John Gallagher on 6/16/15.
//  Copyright © 2014-2015 Big Nerd Ranch. Licensed under MIT.
//

#if SWIFT_PACKAGE
import Deferred
import Result
#endif
import Dispatch

public typealias Cancellation = () -> Void

private func noCancellation() { }

public struct Task<T, Error: ErrorType>: FutureType {
    public typealias Value = Result<T, Error>

    private let task: Future<Value>
    private let cancellation: Cancellation

    private init(task: Future<Value>, cancellation: Cancellation) {
        self.task = task
        self.cancellation = cancellation
    }

    public init<Future: FutureType where Future.Value == Value>(_ future: Future, cancellation: Cancellation = noCancellation) {
        self.init(task: Future(future), cancellation: cancellation)
    }

    public init(value: Result<T, Error>, cancellation: Cancellation = noCancellation) {
        self.init(task: Future(value: value), cancellation: cancellation)
    }

    public init(_ other: Future<Value>, cancellation: Cancellation = noCancellation) {
        self.init(task: other, cancellation: cancellation)
    }

    public init(_ other: Task<T, Error>, cancellation: Cancellation = noCancellation) {
        self.init(task: other.task, cancellation: cancellation)
    }

    /// Call some function once the value is determined.
    ///
    /// If the value is determined, the function should be submitted to the
    /// queue immediately. An `upon` call should always execute asynchronously.
    ///
    /// - parameter queue: A dispatch queue for executing the given function on.
    /// - parameter function: A function that uses the determined value.
    public func upon(queue: dispatch_queue_t, body: Result<T, Error> -> Void) {
        task.upon(queue, body: body)
    }

    /// Waits synchronously for the value to become determined.
    ///
    /// If the value is already determined, the call returns immediately with the
    /// value.
    ///
    /// - parameter time: A length of time to wait for the value to be determined.
    /// - returns: The determined value, if filled within the timeout, or `nil`.
    public func wait(time: Timeout) -> Result<T, Error>? {
        return task.wait(time)
    }

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
