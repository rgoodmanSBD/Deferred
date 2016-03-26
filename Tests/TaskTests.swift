//
//  TaskTests.swift
//  DeferredTests
//
//  Created by John Gallagher on 7/1/15.
//  Copyright © 2014-2015 Big Nerd Ranch. Licensed under MIT.
//

import XCTest
#if SWIFT_PACKAGE
import Result
import Deferred
@testable import Task
#else
@testable import Deferred
#endif

func mockCancellation(expectation: XCTestExpectation?) -> () -> Void {
    return {
        expectation?.fulfill()
    }
}

class CancellableTaskTests: XCTestCase {

    func testThatFlatMapForwardsCancellationToSubsequentTask() {
        let firstTask = Task<Int>(value: .Success(1))
        let expectation = expectationWithDescription("flatMapped task is cancelled")
        let mappedTask = firstTask.flatMap { _ -> Task<Int> in
            let d = Deferred<Result<Int>>()
            return Task(d, cancellation: mockCancellation(expectation))
        }
        mappedTask.cancel()
        waitForExpectationsWithTimeout(TestTimeout, handler: nil)
    }

    func testThatFlatMapSuccessForwardsCancellationToSubsequentTask() {
        let firstTask = Task<Int>(value: .Success(1))
        let expectation = expectationWithDescription("flatMapped task is cancelled")
        let mappedTask = firstTask.flatMapSuccess { _ -> Task<Int> in
            let d = Deferred<Result<Int>>()
            return Task<Int>(d, cancellation: mockCancellation(expectation))
        }
        mappedTask.cancel()
        waitForExpectationsWithTimeout(TestTimeout, handler: nil)
    }

}
