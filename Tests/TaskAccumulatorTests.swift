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
        var tasks = [Task<Void, AnyError>]()
        for i in 0 ..< numTasks {
            let task = Task<Void, AnyError>()
            tasks.append(task)
            accumulator.accumulate(task)

            afterDelay(0.1, queue: queue) {
                // success/failure should be ignored by TaskAccumulator, so try both!
                if i % 2 == 0 {
                    task.fill(.Success(()))
                } else {
                    task.fill(.Failure(.Unit))
                }
            }
        }

        let expectation = expectationWithDescription("allCompleteTask finished")
        accumulator.allCompleteTask().upon(queue) { [weak expectation] _ in
            for task in tasks {
                XCTAssertTrue(task.isFilled)
            }

            expectation?.fulfill()
        }

        waitForExpectationsWithTimeout(4, handler: nil)
    }

    func testThatFinishedTasksAreNotRetained() {
        weak var retainCheck: Task<Void, NoError>?

        let expectation = expectationWithDescription("Task in question finished")
        autoreleasepool {
            let task = Task<Void, NoError>()
            retainCheck = task
            accumulator.accumulate(task)

            afterDelay(0.1, queue: queue) { [weak expectation] in
                task.fill(.Success(()))

                // Postpone fulfilling the expectation by 1 runloop tick so we're
                // sure task will be deallocated (assumine no one else is retaining it)
                dispatch_async(self.queue) { [weak expectation] in
                    expectation?.fulfill()
                }
            }
        }

        XCTAssertNotNil(retainCheck)
        waitForExpectationsWithTimeout(15, handler: nil)
        XCTAssertNil(retainCheck)
    }
}
