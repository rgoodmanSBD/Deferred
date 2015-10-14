//
//  Task.swift
//  Deferred
//
//  Created by John Gallagher on 6/16/15.
//  Copyright © 2014-2015 Big Nerd Ranch. Licensed under MIT.
//

import Foundation
#if SWIFT_PACKAGE
import Deferred
import Result
#endif
import Dispatch

public protocol Cancellable {
    func cancel()
}

extension NSURLSessionTask: Cancellable {}

public final class Task<T, Error: ErrorType>: FutureType {
    private let deferred: Deferred<Result<T, Error>>
    public var task: Cancellable?

    private init(deferred: Deferred<Result<T, Error>>, task: Cancellable?) {
        self.deferred = deferred
        self.task = task
    }

    public init() {
        self.deferred = Deferred()
    }

    public init(value: Result<T, Error>) {
        self.deferred = Deferred(value: value)
    }

    /// Check whether or not the receiver is filled.
    public var isFilled: Bool {
        return deferred.isFilled
    }

    /// Call some function once the value is determined.
    ///
    /// If the value is determined, the function should be submitted to the
    /// queue immediately. An `upon` call should always execute asynchronously.
    ///
    /// - parameter queue: A dispatch queue for executing the given function on.
    /// - parameter function: A function that uses the determined value.
    public func upon(queue: dispatch_queue_t, function: Result<T, Error> -> ()) {
        return deferred.upon(queue, function: function)
    }

    /// Waits synchronously for the value to become determined.
    ///
    /// If the value is already determined, the call returns immediately with the
    /// value.
    ///
    /// - parameter time: A length of time to wait for the value to be determined.
    /// - returns: The determined value, if filled within the timeout, or `nil`.
    public func wait(time: Timeout) -> Result<T, Error>? {
        return deferred.wait(time)
    }

    public func fill(result: Result<T, Error>) {
        deferred.fill(result)
    }

    public func fillIfUnfilled(result: Result<T, Error>) {
        deferred.fill(result, assertIfFilled: false)
    }

    public func ignoringResult() -> Task<Void, Error> {
        return self.mapSuccess { _ in }
    }

    public func ignoringResultAndError() -> Deferred<Void> {
        return deferred.map { _ in }
    }

    public func flatMap<U>(block: Result<T, Error> -> Task<U, Error>) -> Task<U, Error> {
        let cancelForwarder = CancelForwarder(task)
        let mappedDeferred = deferred.flatMap { result -> Deferred<Result<U, Error>> in
            let newTask = block(result)
            cancelForwarder.task = newTask.task
            return newTask.deferred
        }
        return Task<U, Error>(deferred: mappedDeferred, task: cancelForwarder)
    }

    public func map<U>(block: Result<T, Error> -> Result<U, Error>) -> Task<U, Error> {
        let mappedDeferred = deferred.map(transform: block)
        return Task<U, Error>(deferred: mappedDeferred, task: task)
    }

    public func mapSuccess<U>(block: T -> U) -> Task<U, Error> {
        let mappedDeferred = deferred.map { result -> Result<U, Error> in
            switch result {
            case .Success(let value):
                return .Success(block(value))
            case .Failure(let error):
                return .Failure(error)
            }
        }
        return Task<U, Error>(deferred: mappedDeferred, task: task)
    }

    public func flatMapSuccess<U>(block: T -> Result<U, Error>) -> Task<U, Error> {
        let mappedDeferred = deferred.map { $0.flatMap(block) }
        return Task<U, Error>(deferred: mappedDeferred, task: task)
    }

    public func flatMapSuccess<U>(body: T -> Task<U, Error>) -> Task<U, Error> {
        let cancelForwarder = CancelForwarder(task)
        let mappedDeferred = deferred.flatMap(transform: flatMapSuccessBindOperation(cancelForwarder, body))
        return Task<U, Error>(deferred: mappedDeferred, task: cancelForwarder)
    }

    public func flatMapSuccess<U>(queue: dispatch_queue_t, body: T -> Task<U, Error>) -> Task<U, Error> {
        let cancelForwarder = CancelForwarder(task)
        let mappedDeferred = deferred.flatMap(upon: queue, transform: flatMapSuccessBindOperation(cancelForwarder, body))
        return Task<U, Error>(deferred: mappedDeferred, task: cancelForwarder)
    }

    private func flatMapSuccessBindOperation<U>(cancelForwarder: CancelForwarder, _ body: T -> Task<U, Error>) -> Result<T, Error> -> Deferred<Result<U, Error>> {
        return { result -> Deferred<Result<U, Error>> in
            switch result {
            case .Success(let value):
                let newTask = body(value)
                cancelForwarder.task = newTask.task
                return newTask.deferred
            case .Failure(let error):
                return Deferred(value: .Failure(error))
            }
        }
    }

    /// Attempt to cancel the underlying task. This is a "best effort"; there are several
    /// situations in which cancellation will not happen:
    ///
    /// * The task has already completed (racing with isFilled).
    /// * The underlying task has entered an uncancelable state.
    /// * The underlying task is not cancelable.
    public func cancel() {
        task?.cancel()
    }
}

private class CancelForwarder: Cancellable {
    var state: LockProtected<(task: Cancellable?, isCancelled: Bool)>

    init(_ task: Cancellable?) {
        state = LockProtected(item: (task: task, isCancelled: false))
    }

    private func cancel() {
        state.withWriteLock { state -> Void in
            state.task?.cancel()
            state.isCancelled = true
        }
    }

    var task: Cancellable? {
        get {
            return state.withReadLock { $0.task }
        }
        set {
            state.withWriteLock { state -> Void in
                state.task = newValue
                if state.isCancelled {
                    state.task?.cancel()
                }
            }
        }
    }
}

func all<T, Error, Seq: SequenceType where Seq.Generator.Element == Task<T, Error>>(sequence: Seq) -> Task<Void, Error> {
    let incomingTasks = Array(sequence)

    if incomingTasks.isEmpty {
        return Task(value: .Success())
    }

    let completedTaskCount = LockProtected(item: 0)
    let coalescingTask = Task<Void, Error>()

    for task in incomingTasks {
        task.upon { result in
            // fast-track an error if we get one
            if let error = result.error {
                coalescingTask.fillIfUnfilled(.Failure(error))
                return
            }

            // if we haven't failed and we're the last task to finish, fill with success
            let count = completedTaskCount.withWriteLock { (inout c: Int) in ++c }
            if count == incomingTasks.count {
                coalescingTask.fillIfUnfilled(.Success())
            }
        }
    }

    return coalescingTask
}
