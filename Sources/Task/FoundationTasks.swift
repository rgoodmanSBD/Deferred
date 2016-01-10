//
//  FoundationTasks.swift
//  Deferred
//
//  Created by Zachary Waldowski on 1/10/16.
//  Copyright © 2015 Big Nerd Ranch. Licensed under MIT.
//

#if SWIFT_PACKAGE
import Deferred
import Result
#endif
import Foundation

extension NSURLSession {

    private func beginTask<Value, URLTask: NSURLSessionTask>(@noescape configurator configure: URLTask throws -> Void, @noescape makeTask: (completionHandler: (Value?, NSURLResponse?, NSError?) -> Void) -> URLTask) rethrows -> Task<Value> {
        let deferred = Deferred<Result<Value>>()
        func handleCompletion(value: Value?, response: NSURLResponse?, error: NSError?) {
            if let value = value where response != nil {
                deferred.succeed(value)
            } else if let error = error {
                deferred.fail(error)
            } else {
                deferred.fail(NSURLError.BadServerResponse)
            }
        }

        let task = makeTask(completionHandler: handleCompletion)
        try configure(task)
        defer { task.resume() }
        return Task(deferred, cancellation: task.cancel)
    }

    public func beginDataTask(request: NSURLRequest, @noescape configure: NSURLSessionDataTask throws -> Void) rethrows -> Task<NSData> {
        return try beginTask(configurator: configure) {
            dataTaskWithRequest(request, completionHandler: $0)
        }
    }

    public func beginDataTask(request: NSURLRequest) -> Task<NSData> {
        return beginDataTask(request) { _ in }
    }

    public func beginUploadTask(request: NSURLRequest, fromData bodyData: NSData? = nil, @noescape configure: NSURLSessionUploadTask throws -> Void) rethrows -> Task<NSData> {
        return try beginTask(configurator: configure) {
            uploadTaskWithRequest(request, fromData: bodyData, completionHandler: $0)
        }
    }

    public func beginUploadTask(request: NSURLRequest, fromData bodyData: NSData? = nil) -> Task<NSData> {
        return beginUploadTask(request, fromData: bodyData) { _ in }
    }

    public func beginUploadTask(request: NSURLRequest, fromFile fileURL: NSURL, @noescape configure: NSURLSessionUploadTask throws -> Void) rethrows -> Task<NSData> {
        return try beginTask(configurator: configure) {
            uploadTaskWithRequest(request, fromFile: fileURL, completionHandler: $0)
        }
    }

    public func beginUploadTask(request: NSURLRequest, fromFile fileURL: NSURL) -> Task<NSData> {
        return beginUploadTask(request, fromFile: fileURL) { _ in }
    }

}
