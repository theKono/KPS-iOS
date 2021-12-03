//
//  SynchronizedArray.swift
//  KPS
//
//  Created by mingshing on 2021/8/18.
//

import Foundation

public class ThreadSafeArray<T> {
    private var array: [T] = []
    private let accessQueue = DispatchQueue(label: "SynchronizedArrayAccess", attributes: .concurrent)

    public init() { }
        
    public convenience init(_ array: [T]) {
        self.init()
        self.array = array
    }
    
    public func append(_ newElement: T) {
        self.accessQueue.async(flags: .barrier) {
            self.array.append(newElement)
        }
    }

    public func removeAtIndex(index: Int) {
        self.accessQueue.async(flags: .barrier) {
            self.array.remove(at: index)
        }
    }
    
    public var count: Int {
        var val = 0
        self.accessQueue.sync {
            val = self.array.count
        }
        return val
    }
    
    public subscript(index: Int) -> T {
        set {
            self.accessQueue.async(flags: .barrier) {
                self.array[index] = newValue
            }
        }
        get {
            var element: T!

            self.accessQueue.sync() {
                element = self.array[index]
            }

            return element
        }
    }
    
    public func sorted(by areInIncreasingOrder: (T, T) -> Bool) -> ThreadSafeArray {
        var result: ThreadSafeArray?
        accessQueue.sync {
            result = ThreadSafeArray(self.array.sorted(by: areInIncreasingOrder))
            
        }
        return result!
    }
    
    public func items() -> [T] {
        
        return self.array
    }
}
