//
//  TaskForTests.swift
//  DeferredTests
//
//  Created by Zachary Waldowski on 7/14/15.
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

let TestTimeout: NSTimeInterval = 15

enum NoError: ErrorType {}
enum AnyError: ErrorType {
    case Unit
}

func afterDelay(delay: NSTimeInterval, queue: dispatch_queue_t = dispatch_get_main_queue(), perform: () -> ()) {
    let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * NSTimeInterval(NSEC_PER_SEC)))
    dispatch_after(delay, queue, perform)
}

extension XCTestCase {

    func waitForTaskToComplete<T>(task: Task<T>) -> Result<T>! {
        let expectation = expectationWithDescription("task completed")
        var result: Result<T>?
        task.uponMainQueue { [weak expectation] in
            result = $0
            expectation?.fulfill()
        }
        waitForExpectationsWithTimeout(TestTimeout, handler: nil)

        return result
    }

}
