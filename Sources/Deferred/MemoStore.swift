//
//  MemoStore.swift
//  Deferred
//
//  Created by Zachary Waldowski on 12/8/15.
//  Copyright © 2014-2015 Big Nerd Ranch. Licensed under MIT.
//

import Dispatch
import Atomics

// Atomic compare-and-swap, but safe for an initialize-once, owning pointer:
//  - ObjC: "MyObject *__strong *"
//  - Swift: "UnsafeMutablePointer<MyObject!>"
// If the assignment is made, the new value is retained by its owning pointer.
// If the assignment is not made, the new value is not retained.
@_transparent
private func atomicInitialize<T>(_ target: UnsafeMutablePointer<AnyObject?>, to desired: T) -> Bool {
    let newPtr = Unmanaged.passRetained(desired as AnyObject).toOpaque()
    let wonRace = target.withMemoryRebound(to: UnsafeAtomicRawPointer.self, capacity: 1) {
        $0.pointee.compareAndSwap(from: nil, to: newPtr, success: .sequentiallyConsistent, failure: .sequentiallyConsistent)
    }

    if !wonRace {
        Unmanaged<AnyObject>.fromOpaque(newPtr).release()
    }

    return wonRace
}

@_transparent
private func atomicLoad<T>(target: UnsafeMutablePointer<AnyObject?>) -> T? {
    guard let ptr = target.withMemoryRebound(to: UnsafeAtomicRawPointer.self, capacity: 1, {
        $0.pointee.load(order: .relaxed)
    }) else { return nil }
    return Unmanaged<AnyObject>.fromOpaque(ptr).takeUnretainedValue() as? T
}

// Heap storage that is initialized with a value once-and-only-once, atomically.
final class MemoStore<Value>: ManagedBuffer<Void, AnyObject?> {

    // Using `ManagedBuffer` has advantages over a custom class:
    //  - The buffer has a stable pointer when locked to a single element.
    //  - Better `holdsUniqueReference` support allows for future optimization.

    static func create(with value: Value?) -> MemoStore<Value> {
        return unsafeDowncast(create(minimumCapacity: 1, makingHeaderWith: { (buffer) -> Void in
            buffer.withUnsafeMutablePointerToElements { (boxPtr) in
                boxPtr.initialize(to: value.map { $0 as AnyObject })
            }
        }), to: self)
    }

    deinit {
        _ = withUnsafeMutablePointerToElements { (boxPtr) in
            boxPtr.deinitialize()
        }
    }
    
    func withValue(_ body: (Value) -> Void) {
        withUnsafeMutablePointerToElements { boxPtr in
            guard let unboxed: Value = atomicLoad(target: boxPtr) else { return }
            body(unboxed)
        }
    }
    
    func fill(_ value: Value) -> Bool {
        return withUnsafeMutablePointerToElements { boxPtr in
            atomicInitialize(boxPtr, to: value as AnyObject)
        }
    }
}
