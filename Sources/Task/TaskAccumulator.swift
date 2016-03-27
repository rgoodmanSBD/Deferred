//
//  TaskAccumulator.swift
//  Deferred
//
//  Created by John Gallagher on 8/18/15.
//  Copyright © 2014-2015 Big Nerd Ranch. Licensed under MIT.
//

#if SWIFT_PACKAGE
import Deferred
import Result
#endif
import Dispatch

/// TaskAccumulator is a tool to support our *Store classes that need to
/// shut down when the user logs out. In order to shut down cleanly, we need
/// to wait for all tasks the stores may have in flight to complete so we can
/// tear down Core Data. TaskAccumulator can be given any number of tasks
/// (via accumulate()), and allCompleteTask() can be called to get a Task that
/// will be filled (with success) once all accumulated tasks have completed.
/// The success or failure of the accumulated tasks is IGNORED - TaskAccumulator
/// is only interested in completion.
public final class TaskAccumulator {
    private let group = dispatch_group_create()!

    public init() {}

    /// Accumulate another task into the list of tasks that fold into `allCompleteTask`.
    ///
    /// This method is thread-safe.
    public func accumulate<T>(task: Task<T>) {
        dispatch_group_enter(group)
        task.upon { _ in dispatch_group_leave(self.group) }
    }

    /// Generate a deferred which will be filled once all tasks given to this instance
    /// of TaskAccumulator have completed.
    ///
    /// This function is thread-safe; however, there is an inherent race condition
    /// if this method is being called at the same time as `accumulate` (whether the
    /// task being currently accumulated will be included in this call to allCompleteTask
    /// is racy).
    public func allCompleteTask() -> Deferred<Void> {
        let deferred = Deferred<Void>()
        dispatch_group_notify(group, Deferred<Void>.genericQueue) {
            deferred.fill(())
        }
        return deferred
    }
}
