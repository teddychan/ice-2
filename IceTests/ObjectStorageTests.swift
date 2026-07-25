//
//  ObjectStorageTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

/// Covers the associated-object storage Ice uses to attach state to AppKit
/// objects it doesn't own. Getting the strong/weak distinction wrong here
/// leaks windows and panels, so both are pinned down.
struct ObjectStorageTests {
    private final class Payload {
        let id: Int
        init(id: Int) {
            self.id = id
        }
    }

    // MARK: Strong storage

    @Test func valueIsNilBeforeAnythingIsStored() {
        let storage = ObjectStorage<String>()
        #expect(storage.value(for: NSObject()) == nil)
    }

    @Test func storedValueIsRetrievable() {
        let storage = ObjectStorage<String>()
        let owner = NSObject()
        storage.set("hello", for: owner)
        #expect(storage.value(for: owner) == "hello")
    }

    @Test func storingAgainOverwritesTheValue() {
        let storage = ObjectStorage<String>()
        let owner = NSObject()
        storage.set("first", for: owner)
        storage.set("second", for: owner)
        #expect(storage.value(for: owner) == "second")
    }

    @Test func settingNilClearsTheValue() {
        let storage = ObjectStorage<String>()
        let owner = NSObject()
        storage.set("hello", for: owner)
        storage.set(nil, for: owner)
        #expect(storage.value(for: owner) == nil)
    }

    @Test func eachOwnerHasItsOwnValue() {
        let storage = ObjectStorage<String>()
        let first = NSObject()
        let second = NSObject()
        storage.set("first", for: first)
        storage.set("second", for: second)
        #expect(storage.value(for: first) == "first")
        #expect(storage.value(for: second) == "second")
    }

    @Test func separateStorageInstancesDoNotCollideOnTheSameOwner() {
        // The lookup key is derived from the storage instance itself.
        let a = ObjectStorage<String>()
        let b = ObjectStorage<String>()
        let owner = NSObject()
        a.set("from a", for: owner)
        b.set("from b", for: owner)
        #expect(a.value(for: owner) == "from a")
        #expect(b.value(for: owner) == "from b")
    }

    @Test func strongStorageKeepsTheValueAlive() {
        let storage = ObjectStorage<Payload>()
        let owner = NSObject()
        var payload: Payload? = Payload(id: 1)
        storage.set(payload, for: owner)
        payload = nil
        // `set` retains, so dropping the local reference changes nothing.
        #expect(storage.value(for: owner)?.id == 1)
    }

    // MARK: Weak storage

    @Test func weakStoredValueIsRetrievableWhileAlive() {
        let storage = ObjectStorage<Payload>()
        let owner = NSObject()
        let payload = Payload(id: 7)
        storage.weakSet(payload, for: owner)
        #expect(storage.value(for: owner) === payload)
    }

    @Test func weakStoredValueDisappearsWhenReleased() {
        let storage = ObjectStorage<Payload>()
        let owner = NSObject()
        var payload: Payload? = Payload(id: 2)
        storage.weakSet(payload, for: owner)
        #expect(storage.value(for: owner) != nil)
        payload = nil
        // The wrapper survives, but the reference inside it is gone.
        #expect(storage.value(for: owner) == nil)
    }

    @Test func weakSetNilClearsTheValue() {
        let storage = ObjectStorage<Payload>()
        let owner = NSObject()
        storage.weakSet(Payload(id: 3), for: owner)
        storage.weakSet(nil, for: owner)
        #expect(storage.value(for: owner) == nil)
    }

    @Test func weakSetReplacesAPreviouslyStrongValue() {
        let storage = ObjectStorage<Payload>()
        let owner = NSObject()
        storage.set(Payload(id: 4), for: owner)
        var replacement: Payload? = Payload(id: 5)
        storage.weakSet(replacement, for: owner)
        #expect(storage.value(for: owner)?.id == 5)
        replacement = nil
        #expect(storage.value(for: owner) == nil)
    }
}
