//
//  RWLock.swift
//  CrumbPath
//
//  Created by Backlin,Gene on 2/20/18.
//  Copyright © 2018 Backlin,Gene. All rights reserved.
//
//  Originally developed by:
//  Created by Kyle Jessup on 2015-12-03.
//  Copyright © 2015 PerfectlySoft. All rights reserved.
//
// https://github.com/PerfectlySoft/Perfect-Thread/blob/master/Sources/Threading.swift
//
import Foundation

/// A read-write thread lock.
/// Permits multiple readers to hold the while, while only allowing at most one writer to hold the lock.
/// For a writer to acquire the lock all readers must have unlocked.
/// For a reader to acquire the lock no writers must hold the lock.
public final class RWLock {
    
    var lock = pthread_rwlock_t()
    
    /// Initialize a new read-write lock.
    public init() {
        pthread_rwlock_init(&self.lock, nil)
    }
    
    deinit {
        pthread_rwlock_destroy(&self.lock)
    }
    
    /// Attempt to acquire the lock for reading.
    /// Returns false if an error occurs.
    @discardableResult
    public func readLock() -> Bool {
        return 0 == pthread_rwlock_rdlock(&self.lock)
    }
    
    /// Attempts to acquire the lock for reading.
    /// Returns false if the lock is held by a writer or an error occurs.
    public func tryReadLock() -> Bool {
        return 0 == pthread_rwlock_tryrdlock(&self.lock)
    }
    
    /// Attempt to acquire the lock for writing.
    /// Returns false if an error occurs.
    @discardableResult
    public func writeLock() -> Bool {
        return 0 == pthread_rwlock_wrlock(&self.lock)
    }
    
    /// Attempt to acquire the lock for writing.
    /// Returns false if the lock is held by readers or a writer or an error occurs.
    public func tryWriteLock() -> Bool {
        return 0 == pthread_rwlock_trywrlock(&self.lock)
    }
    
    /// Unlock a lock which is held for either reading or writing.
    /// Returns false if an error occurs.
    @discardableResult
    public func unlock() -> Bool {
        return 0 == pthread_rwlock_unlock(&self.lock)
    }
    
    /// Acquire the read lock, execute the closure, release the lock.
    public func doWithReadLock<Result>(closure: () throws -> Result) rethrows -> Result {
        _ = self.readLock()
        defer {
            _ = self.unlock()
        }
        return try closure()
    }
    
    /// Acquire the write lock, execute the closure, release the lock.
    public func doWithWriteLock<Result>(closure: () throws -> Result) rethrows -> Result {
        _ = self.writeLock()
        defer {
            _ = self.unlock()
        }
        return try closure()
    }
}

