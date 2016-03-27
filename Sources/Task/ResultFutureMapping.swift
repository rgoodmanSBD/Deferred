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

public extension FutureType where Value: ResultType {

    private typealias OldValue = Value.Value
    private typealias Error = Value.Error

    func flatMap<NewValue>(upon queue: dispatch_queue_t = Self.genericQueue, _ body: Value -> Task<NewValue, Error>) -> Task<NewValue, Error> {
        let cancellationToken = Deferred<Void>()
        let mapped = flatMap(upon: queue) { result -> Future<Result<NewValue, Error>> in
            let newTask = body(result)
            cancellationToken.upon(newTask.cancel)
            return Future(newTask)
        }
        return Task(mapped) { _ = cancellationToken.fill() }
    }

    func flatMapSuccess<NewValue>(upon queue: dispatch_queue_t = Self.genericQueue, _ body: OldValue -> Task<NewValue, Error>) -> Task<NewValue, Error> {
        let cancellationToken = Deferred<Void>()
        let mapped = flatMap(upon: queue) { result -> Future<Result<NewValue, Error>> in
            result.analysis(ifSuccess: { value in
                let newTask = body(value)
                cancellationToken.upon(newTask.cancel)
                return Future(newTask)
            }, ifFailure: { error in
                Future(value: .Failure(error))
            })
        }
        return Task(mapped) { _ = cancellationToken.fill() }
    }

    func flatMapSuccess<NewResult: ResultType where NewResult.Error == Error>(upon queue: dispatch_queue_t = Self.genericQueue, _ body: OldValue -> NewResult) -> Task<NewResult.Value, Error> {
        let mapped = map(upon: queue) {
            $0.analysis(ifSuccess: body, ifFailure: NewResult.init)
        }
        return Task(mapped)
    }

    func map<NewValue>(upon queue: dispatch_queue_t = Self.genericQueue, _ transform: OldValue -> NewValue) -> Task<NewValue, Error> {
        let mapped = map(upon: queue) {
            $0.map(transform)
        }
        return Task(mapped)
    }

}

public extension Task {

    func flatMapSuccess<NewResult: ResultType where NewResult.Error == Error>(upon queue: dispatch_queue_t = Task<T>.genericQueue, _ body: T -> NewResult) -> Task<NewResult.Value, Error> {
        let mapped = map(upon: queue) {
            $0.analysis(ifSuccess: body, ifFailure: NewResult.init)
        }
        return Task<NewResult.Value, Error>(mapped, cancellation: cancel)
    }

    func map<NewValue>(upon queue: dispatch_queue_t = Task<T>.genericQueue, _ transform: T -> NewValue) -> Task<NewValue, Error> {
        let mapped = map(upon: queue) {
            $0.map(transform)
        }
        return Task<NewValue, Error>(mapped, cancellation: cancel)
    }

    var ignoringSuccess: Task<Void, Error> {
        return map { _ in }
    }

}
