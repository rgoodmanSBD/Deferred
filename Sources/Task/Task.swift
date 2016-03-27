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

public func NoCancellation() { }

private extension PromiseType where Value == Void {

    func fill() {
        _ = try? self.fill(())
    }

}

public final class Task<T, Error: ErrorType>: FutureType {
    private let deferred: Deferred<Result<T, Error>>
    private let cancellation: Cancellation

    internal init(deferred: Deferred<Result<T, Error>>, cancellation: Cancellation) {
        self.deferred = deferred
        self.cancellation = cancellation
    }

    public convenience init(cancellation: Cancellation = NoCancellation) {
        self.init(deferred: Deferred(), cancellation: cancellation)
    }

    public convenience init(value: Result<T, Error>, cancellation: Cancellation = NoCancellation) {
        self.init(deferred: Deferred(value: value), cancellation: cancellation)
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
    public func upon(queue: dispatch_queue_t, body: Result<T, Error> -> Void) {
        deferred.upon(queue, body: body)
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

    public func ignoringResult() -> Task<Void, Error> {
        return self.mapSuccess { _ in }
    }

    public func ignoringResultAndError() -> Deferred<Void> {
        return deferred.map { _ in }
    }

    public func flatMap<U>(block: Result<T, Error> -> Task<U, Error>) -> Task<U, Error> {
        let cancellationToken = Deferred<Void>()
        let mappedDeferred = deferred.flatMap { result -> Deferred<Result<U, Error>> in
            let newTask = block(result)
            cancellationToken.upon(newTask.cancellation)
            return newTask.deferred
        }
        return Task<U, Error>(deferred: mappedDeferred, cancellation: cancellationToken.fill)
    }

    public func map<U>(block: Result<T, Error> -> Result<U, Error>) -> Task<U, Error> {
        let mappedDeferred = deferred.map(transform: block)
        return Task<U, Error>(deferred: mappedDeferred, cancellation: cancellation)
    }

    public func mapSuccess<U>(block: T -> U) -> Task<U, Error> {
        let mappedDeferred = deferred.map { result in
            result.analysis(ifSuccess: { .Success(block($0)) }, ifFailure: Result.Failure)
        }
        return Task<U, Error>(deferred: mappedDeferred, cancellation: cancellation)
    }

    public func flatMapSuccess<U>(block: T -> Result<U, Error>) -> Task<U, Error> {
        let mappedDeferred = deferred.map { $0.flatMap(block) }
        return Task<U, Error>(deferred: mappedDeferred, cancellation: cancellation)
    }

    public func flatMapSuccess<U>(upon queue: dispatch_queue_t = Self.genericQueue, body: T -> Task<U, Error>) -> Task<U, Error> {
        let cancellationToken = Deferred<Void>()
        let mappedDeferred = deferred.flatMap(transform: flatMapSuccessBindOperation(cancellationToken, body))
        return Task<U, Error>(deferred: mappedDeferred, cancellation: cancellationToken.fill)
    }

    private func flatMapSuccessBindOperation<U>(cancel: Deferred<Void>, _ body: T -> Task<U, Error>)(result: Result<T, Error>) -> Deferred<Result<U, Error>> {
        switch result {
        case .Success(let value):
            let newTask = body(value)
            cancel.upon(newTask.cancellation)
            return newTask.deferred
        case .Failure(let error):
            return Deferred(value: .Failure(error))
        }
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
