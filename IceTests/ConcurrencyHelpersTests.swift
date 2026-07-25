//
//  ConcurrencyHelpersTests.swift
//  IceTests
//

import Foundation
import Testing
import os.lock
@testable import Ice_2

/// Covers the task-timeout wrapper and the once-only claim used to guarantee
/// continuations resume exactly once (menu bar item moves, app relaunches).
struct ConcurrencyHelpersTests {
    // MARK: TaskTimeoutError

    @Test func timeoutErrorDescriptionsAgree() {
        let error = TaskTimeoutError()
        #expect(error.description == "Task timed out before completion")
        #expect(error.errorDescription == error.description)
    }

    // MARK: Task(timeout:)

    @Test func taskWithTimeoutReturnsAFastResult() async throws {
        let task = Task<Int, any Error>(timeout: .seconds(10)) { 42 }
        #expect(try await task.value == 42)
    }

    @Test func taskWithTimeoutThrowsWhenTheOperationIsTooSlow() async {
        let task = Task<Int, any Error>(timeout: .milliseconds(50)) {
            try await Task.sleep(for: .seconds(30))
            return 0
        }
        await #expect(throws: TaskTimeoutError.self) {
            _ = try await task.value
        }
    }

    @Test func taskWithTimeoutPropagatesTheOperationsOwnError() async {
        struct Boom: Error {}
        let task = Task<Int, any Error>(timeout: .seconds(10)) {
            throw Boom()
        }
        await #expect(throws: Boom.self) {
            _ = try await task.value
        }
    }

    @Test func taskWithTimeoutCancelsTheOperationOnTimeout() async throws {
        let finished = OSAllocatedUnfairLock(initialState: false)
        let task = Task<Int, any Error>(timeout: .milliseconds(50)) {
            try await Task.sleep(for: .seconds(30))
            finished.withLock { $0 = true }
            return 1
        }
        _ = try? await task.value
        // Give the cancelled child a moment to unwind.
        try await Task.sleep(for: .milliseconds(100))
        #expect(finished.withLock { $0 } == false)
    }

    // MARK: Task.detached(timeout:)

    @Test func detachedTaskWithTimeoutReturnsAFastResult() async throws {
        let task = Task<Int, any Error>.detached(timeout: .seconds(10)) { 7 }
        #expect(try await task.value == 7)
    }

    @Test func detachedTaskWithTimeoutThrowsWhenTheOperationIsTooSlow() async {
        let task = Task<Int, any Error>.detached(timeout: .milliseconds(50)) {
            try await Task.sleep(for: .seconds(30))
            return 0
        }
        await #expect(throws: TaskTimeoutError.self) {
            _ = try await task.value
        }
    }

    // MARK: tryClaimOnce

    @Test func tryClaimOnceSucceedsExactlyOnceSequentially() {
        let lock = OSAllocatedUnfairLock(initialState: false)
        #expect(lock.tryClaimOnce())
        #expect(!lock.tryClaimOnce())
        #expect(!lock.tryClaimOnce())
    }

    @Test func tryClaimOnceLeavesTheStateClaimed() {
        let lock = OSAllocatedUnfairLock(initialState: false)
        _ = lock.tryClaimOnce()
        #expect(lock.withLock { $0 } == true)
    }

    @Test func tryClaimOnceRejectsAnAlreadyClaimedState() {
        let lock = OSAllocatedUnfairLock(initialState: true)
        #expect(!lock.tryClaimOnce())
    }

    @Test func tryClaimOnceIsAtomicUnderContention() async {
        let lock = OSAllocatedUnfairLock(initialState: false)
        let winners = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<64 {
                group.addTask { lock.tryClaimOnce() }
            }
            var count = 0
            for await claimed in group where claimed {
                count += 1
            }
            return count
        }
        #expect(winners == 1)
    }
}
