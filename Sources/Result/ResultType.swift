//
//  ResultType.swift
//  Deferred
//
//  Created by Zachary Waldowski on 12/9/15.
//  Copyright © 2014-2015 Big Nerd Ranch. Licensed under MIT.
//

/// A type that can exclusively represent either some result value of a
/// successful computation or a failure with an error.
public protocol ResultType: CustomStringConvertible, CustomDebugStringConvertible {
	associatedtype Value

	/// Creates a result with a successful `value`.
	init(value: Value)

    /// Creates a failed result with `error`.
	init(error: ErrorType)

	/// Case analysis.
	///
	/// Returns the value returned by `ifFailure` if `self` represents a
    /// failure, or `ifSuccess` if `self` represents a success.
	func analysis<Return>(@noescape ifSuccess ifSuccess: Value throws -> Return, @noescape ifFailure: ErrorType throws -> Return) rethrows -> Return
}

extension ResultType {

    /// A textual representation of `self`.
    public var description: String {
        return analysis(ifSuccess: { String($0) }, ifFailure: { String($0) })
    }

    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        return analysis(ifSuccess: {
            "Success(\(String(reflecting: $0)))"
        }, ifFailure: {
            "Failure(\(String(reflecting: $0)))"
        })
    }

}
