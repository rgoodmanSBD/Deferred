//
//  ResultFutureMapping.swift
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

extension FutureType where Value: ResultType {

    private typealias OldValue = Value.Value

    private func mapImpl<NewValue>(upon queue: dispatch_queue_t, _ body: OldValue throws -> NewValue) -> Future<Result<NewValue>> {
        return map(upon: queue) { result -> Result<NewValue> in
            return result.analysis(ifSuccess: { value in
                Result { try body(value) }
            }, ifFailure: Result.Failure)
        }
    }

    private func recoverImpl(upon queue: dispatch_queue_t, _ body: ErrorType throws -> OldValue) -> Future<Result<OldValue>> {
        return map(upon: queue) { result -> Result<OldValue> in
            return result.analysis(ifSuccess: Result.Success, ifFailure: { error in
                Result { try body(error) }
            })
        }
    }

    public func map<NewValue>(upon queue: dispatch_queue_t = Self.genericQueue, _ body: OldValue throws -> NewValue) -> Task<NewValue> {
        let mapped = mapImpl(upon: queue, body)
        return Task(mapped, cancellation: { _ in })
    }

    public func recover(upon queue: dispatch_queue_t = Self.genericQueue, _ body: ErrorType throws -> OldValue) -> Task<OldValue> {
        let mapped = recoverImpl(upon: queue, body)
        return Task(mapped, cancellation: { _ in })
    }

    public func flatMap<NewValue>(upon queue: dispatch_queue_t = Self.genericQueue, _ body: OldValue throws -> Task<NewValue>) -> Task<NewValue> {
        let cancellationToken = Deferred<Void>()
        let mapped = flatMap(upon: queue) { (result: Value) -> Task<NewValue> in
            do {
                let newTask = try result.flatMap(body)
                cancellationToken.upon(newTask.cancel)
                return newTask
            } catch {
                return Task(value: .Failure(error))
            }
        }
        return Task(mapped) { _ = cancellationToken.fill() }
    }

}

public extension Task {

    public func map<NewValue>(upon queue: dispatch_queue_t = Task<T>.genericQueue, _ body: T throws -> NewValue) -> Task<NewValue> {
        let mapped = mapImpl(upon: queue, body)
        return Task<NewValue>(mapped, cancellation: cancel)
    }

    public func recover(upon queue: dispatch_queue_t = Task<T>.genericQueue, _ body: ErrorType throws -> T) -> Task<T> {
        let mapped = recoverImpl(upon: queue, body)
        return Task(mapped, cancellation: cancel)
    }

}

extension ResultType {

    public func flatMap<NewValue>(@noescape body: Value throws -> Task<NewValue>) rethrows -> Task<NewValue> {
        return try analysis(ifSuccess: body, ifFailure: { error in
            Task(value: .Failure(error))
        })
    }

}
