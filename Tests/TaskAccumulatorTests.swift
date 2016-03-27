//
//  TaskAccumulatorTests.swift
//  DeferredTests
//
//  Created by John Gallagher on 8/18/15.
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

class TaskAccumulatorTests: XCTestCase {

    let queue = dispatch_queue_create("TaskAccumulatorTests", DISPATCH_QUEUE_CONCURRENT)
    var accumulator: TaskAccumulator!

    override func setUp() {
        super.setUp()
        accumulator = TaskAccumulator()
    }

    override func tearDown() {
        accumulator = nil
        super.tearDown()
    }

    func testThatAllCompleteTaskWaitsForAllAccumulatedTasks() {
        let numTasks = 20
        var tasks = [Task<Void>]()
        for i in 0 ..< numTasks {
            let deferred = Deferred<Result<Void>>()
            let task = Task<Void>(deferred)
            tasks.append(task)
            accumulator.accumulate(task)

            afterDelay(0.1, queue: queue) {
                // success/failure should be ignored by TaskAccumulator, so try both!
                if i % 2 == 0 {
                    deferred.fill(.Success(()))
                } else {
                    deferred.fill(.Failure(AnyError.Unit))
                }
            }
        }

        let expectation = expectationWithDescription("allCompleteTask finished")
        accumulator.allCompleteTask().upon(queue) { [weak expectation] _ in
            for task in tasks {
                XCTAssertNotNil(task.wait(.Forever))
            }

            expectation?.fulfill()
        }

        waitForExpectationsWithTimeout(4, handler: nil)
    }
}
