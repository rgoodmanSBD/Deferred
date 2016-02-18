//
//  ResultType.swift
//  Result
//
//  Created by Zachary Waldowski on 12/9/15.
//  Copyright © 2014-2015 Big Nerd Ranch. Licensed under MIT.
//

/// An enum for returning and propogating recoverable errors.
public enum Result<Value> {
    /// Contains the success value
    case Success(Value)
    /// Contains the error value
    case Failure(ErrorType)
}

extension Result: ResultType {

    /// Creates a result with a successful `value`.
    public init(value: Value) {
        self = .Success(value)
    }

    /// Creates a failed result with `error`.
    public init(error: ErrorType) {
        self = .Failure(error)
    }

    /// Case analysis.
    ///
    /// Returns the value returned by `ifFailure` if `self` represents a
    /// failure, or `ifSuccess` if `self` represents a success.
    public func analysis<Return>(@noescape ifSuccess ifSuccess: Value throws -> Return, @noescape ifFailure: ErrorType throws -> Return) rethrows -> Return {
        switch self {
        case let .Success(value): return try ifSuccess(value)
        case let .Failure(error): return try ifFailure(error)
        }
    }

}
