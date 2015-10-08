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

private class MockCancellable: Cancellable {
    weak var expectation: XCTestExpectation?

    init(_ expectation: XCTestExpectation?) {
        self.expectation = expectation
    }

    func cancel() {
        expectation?.fulfill()
    }
}

class CancellableTaskTests: XCTestCase {

    func testThatFlatMapForwardsCancellationToSubsequentTask() {
        let firstTask = Task<Int, NoError>(value: .Success(1))
        let expectation = expectationWithDescription("flatMapped task is cancelled")
        let mappedTask = firstTask.flatMap { [weak expectation] _ -> Task<Int, NoError> in
            let task = Task<Int, NoError>()
            task.task = MockCancellable(expectation)
            return task
        }
        mappedTask.cancel()
        waitForExpectationsWithTimeout(TestTimeout, handler: nil)
    }

    func testThatFlatMapSuccessForwardsCancellationToSubsequentTask() {
        let firstTask = Task<Int, NoError>(value: .Success(1))
        let expectation = expectationWithDescription("flatMapped task is cancelled")
        let mappedTask = firstTask.flatMapSuccess { [weak expectation] _ -> Task<Int, NoError> in
            let task = Task<Int, NoError>()
            task.task = MockCancellable(expectation)
            return task
        }
        mappedTask.cancel()
        waitForExpectationsWithTimeout(TestTimeout, handler: nil)
    }

}
