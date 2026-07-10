//
//  ExtensionsTests.swift
//  IceTests
//

import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import Ice_2

struct ExtensionsTests {
    // MARK: Comparable.clamped

    @Test func clampedMinMaxWithinBoundsReturnsValue() {
        #expect(5.clamped(min: 0, max: 10) == 5)
    }

    @Test func clampedMinMaxBelowAndAboveBounds() {
        #expect((-3).clamped(min: 0, max: 10) == 0)
        #expect(42.clamped(min: 0, max: 10) == 10)
    }

    @Test func clampedToRange() {
        #expect(5.0.clamped(to: 1.0...3.0) == 3.0)
        #expect(0.0.clamped(to: 1.0...3.0) == 1.0)
        #expect(2.0.clamped(to: 1.0...3.0) == 2.0)
    }

    @Test func clampedAtExactBounds() {
        #expect(0.clamped(min: 0, max: 10) == 0)
        #expect(10.clamped(min: 0, max: 10) == 10)
    }

    // MARK: RangeReplaceableCollection.removingDuplicates

    @Test func removingDuplicatesPreservesFirstOccurrenceOrder() {
        #expect([1, 2, 2, 3, 1, 4].removingDuplicates() == [1, 2, 3, 4])
        #expect(["a", "a", "b"].removingDuplicates() == ["a", "b"])
    }

    @Test func removingDuplicatesOnEmptyAndUnique() {
        #expect([Int]().removingDuplicates() == [])
        #expect([1, 2, 3].removingDuplicates() == [1, 2, 3])
    }

    // MARK: CGColor.brightness

    @Test func brightnessOfWhiteAndBlack() throws {
        let white = try #require(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1).brightness)
        let black = try #require(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1).brightness)
        #expect(abs(white - 1) < 0.01)
        #expect(abs(black - 0) < 0.01)
    }

    @Test func brightnessWeightsGreenMostHeavily() throws {
        // Per the W3C AERT formula, green (587) outweighs red (299) and blue (114).
        let red = try #require(CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1).brightness)
        let green = try #require(CGColor(srgbRed: 0, green: 1, blue: 0, alpha: 1).brightness)
        let blue = try #require(CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1).brightness)
        #expect(green > red)
        #expect(red > blue)
    }

    // MARK: EdgeInsets

    @Test func edgeInsetsInitAllSetsEveryEdge() {
        let insets = EdgeInsets(all: 7)
        #expect(insets.top == 7)
        #expect(insets.leading == 7)
        #expect(insets.bottom == 7)
        #expect(insets.trailing == 7)
    }

    @Test func edgeInsetsHorizontalZeroesVerticalEdges() {
        let insets = EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4).horizontal
        #expect(insets.top == 0)
        #expect(insets.leading == 2)
        #expect(insets.bottom == 0)
        #expect(insets.trailing == 4)
    }

    @Test func edgeInsetsVerticalZeroesHorizontalEdges() {
        let insets = EdgeInsets(top: 1, leading: 2, bottom: 3, trailing: 4).vertical
        #expect(insets.top == 1)
        #expect(insets.leading == 0)
        #expect(insets.bottom == 3)
        #expect(insets.trailing == 0)
    }
}
