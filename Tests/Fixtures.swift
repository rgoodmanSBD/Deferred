//
//  Fixtures.swift
//  DeferredTests
//
//  Created by Zachary Waldowski on 6/10/15.
//  Copyright © 2014-2015 Big Nerd Ranch. Licensed under MIT.
//

import XCTest
@testable import Deferred
#if SWIFT_PACKAGE
import Result
#endif

let TestTimeout: NSTimeInterval = 15

enum Error: ErrorType {
    case First
    case Second
    case Third
}

func after(delay delay: NSTimeInterval, upon queue: dispatch_queue_t = dispatch_get_main_queue(), perform: () -> ()) {
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

extension ResultType {
    var value: Value? {
        return analysis(ifSuccess: { $0 }, ifFailure: { _ in nil })
    }

    var error: ErrorType? {
        return analysis(ifSuccess: { _ in nil }, ifFailure: { $0 })
    }
}
