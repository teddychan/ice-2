//
//  SharedExtensionsTests.swift
//  IceTests
//

import CoreGraphics
import Dispatch
import Foundation
import Testing
@testable import Ice_2

/// Covers the geometry and dispatch helpers shared between the app and the
/// menu bar item XPC service.
struct SharedExtensionsTests {
    // MARK: CGPoint.distance

    @Test func distanceMatchesPythagoras() {
        #expect(CGPoint(x: 0, y: 0).distance(to: CGPoint(x: 3, y: 4)) == 5)
        #expect(CGPoint(x: -3, y: -4).distance(to: .zero) == 5)
    }

    @Test func distanceToSelfIsZero() {
        let point = CGPoint(x: 12.5, y: -7)
        #expect(point.distance(to: point) == 0)
    }

    @Test func distanceIsSymmetric() {
        let a = CGPoint(x: 1, y: 9)
        let b = CGPoint(x: -4, y: 2)
        #expect(a.distance(to: b) == b.distance(to: a))
    }

    @Test func distanceIgnoresAxisSign() {
        // Only the magnitude of each delta matters.
        #expect(CGPoint(x: 0, y: 0).distance(to: CGPoint(x: -3, y: 4)) == 5)
        #expect(CGPoint(x: 0, y: 0).distance(to: CGPoint(x: 3, y: -4)) == 5)
    }

    // MARK: CGRect.center

    @Test func centerIsTheMidpointOfTheRect() {
        #expect(CGRect(x: 10, y: 20, width: 30, height: 40).center == CGPoint(x: 25, y: 40))
    }

    @Test func centerOfZeroSizedRectIsItsOrigin() {
        #expect(CGRect(x: 5, y: 6, width: 0, height: 0).center == CGPoint(x: 5, y: 6))
    }

    @Test func centerHandlesNegativeOrigins() {
        #expect(CGRect(x: -10, y: -10, width: 4, height: 6).center == CGPoint(x: -8, y: -7))
    }

    // MARK: CGError.logString

    @Test func logStringNamesEveryKnownError() {
        let expected: [(CGError, String)] = [
            (.success, "success"),
            (.failure, "failure"),
            (.illegalArgument, "illegalArgument"),
            (.invalidConnection, "invalidConnection"),
            (.invalidContext, "invalidContext"),
            (.cannotComplete, "cannotComplete"),
            (.notImplemented, "notImplemented"),
            (.rangeCheck, "rangeCheck"),
            (.typeCheck, "typeCheck"),
            (.invalidOperation, "invalidOperation"),
            (.noneAvailable, "noneAvailable"),
        ]
        for (error, name) in expected {
            #expect(error.logString == "\(error.rawValue): \(name)")
        }
    }

    @Test func logStringForUnknownErrorFallsBackToUnknown() {
        // Guards the @unknown default branch against future CGError cases.
        let unknown = CGError(rawValue: 9999)
        #expect(unknown?.logString == "9999: unknown")
    }

    // MARK: DispatchQueue.targetingGlobal

    @Test func targetingGlobalPreservesTheLabel() {
        let queue = DispatchQueue.targetingGlobal(label: "com.dragonapp.ice.tests.serial")
        #expect(queue.label == "com.dragonapp.ice.tests.serial")
    }

    @Test func targetingGlobalQueueExecutesWork() {
        let queue = DispatchQueue.targetingGlobal(label: "com.dragonapp.ice.tests.exec")
        var value = 0
        queue.sync { value = 42 }
        #expect(value == 42)
    }

    @Test func targetingGlobalAcceptsConcurrentAttributesAndQoS() {
        let queue = DispatchQueue.targetingGlobal(
            label: "com.dragonapp.ice.tests.concurrent",
            qos: .userInitiated,
            attributes: .concurrent
        )
        #expect(queue.label == "com.dragonapp.ice.tests.concurrent")

        // A concurrent queue still runs every submitted block.
        let group = DispatchGroup()
        let counter = NSCountedSet()
        for index in 0..<8 {
            queue.async(group: group) {
                objc_sync_enter(counter)
                counter.add(index)
                objc_sync_exit(counter)
            }
        }
        #expect(group.wait(timeout: .now() + 5) == .success)
        #expect(counter.count == 8)
    }
}
