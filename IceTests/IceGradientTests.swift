//
//  IceGradientTests.swift
//  IceTests
//

import AppKit
import CoreGraphics
import Foundation
import Testing
@testable import Ice_2

struct IceGradientTests {
    private var blackToWhite: IceGradient {
        IceGradient(stops: [.white(location: 0), .black(location: 1)])
    }

    // MARK: ColorStop

    @Test func colorStopFactories() {
        let white = IceGradient.ColorStop.white(location: 0.25)
        #expect(white.location == 0.25)
        #expect(white.color.components == [1, 1, 1, 1])

        let black = IceGradient.ColorStop.black(location: 0.75)
        #expect(black.location == 0.75)
        #expect(black.color.components == [0, 0, 0, 1])

        let custom = IceGradient.ColorStop.stop(CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1), location: 0.5)
        #expect(custom.location == 0.5)
    }

    @Test func colorStopWithAlpha() {
        let stop = IceGradient.ColorStop.white(location: 0).withAlpha(0.5)
        #expect(stop.color.alpha == 0.5)
    }

    @Test func colorStopWithLocation() {
        let stop = IceGradient.ColorStop.black(location: 0).withLocation(0.9)
        #expect(stop.location == 0.9)
    }

    @Test func colorStopCodableRoundTrip() throws {
        let stop = IceGradient.ColorStop.stop(CGColor(srgbRed: 0.1, green: 0.2, blue: 0.3, alpha: 1), location: 0.4)
        let data = try JSONEncoder().encode(stop)
        let decoded = try JSONDecoder().decode(IceGradient.ColorStop.self, from: data)
        #expect(decoded.location == stop.location)
    }

    // MARK: IceGradient

    @Test func defaultInitIsEmpty() {
        #expect(IceGradient().stops.isEmpty)
    }

    @Test func defaultMenuBarTintIsWhiteToBlack() {
        let tint = IceGradient.defaultMenuBarTint
        #expect(tint.stops.count == 2)
        #expect(tint.stops[0].location == 0)
        #expect(tint.stops[1].location == 1)
    }

    @Test func withAlphaAppliesToAllStops() {
        let faded = blackToWhite.withAlpha(0.5)
        #expect(faded.stops.count == 2)
        #expect(faded.stops.allSatisfy { $0.color.alpha == 0.5 })
    }

    @Test func nsGradientNilForEmptyGradient() {
        #expect(IceGradient().nsGradient(using: .genericRGB) == nil)
    }

    @Test func nsGradientNonNilForPopulatedGradient() {
        #expect(blackToWhite.nsGradient(using: .genericRGB) != nil)
    }

    @Test func colorAtEndpointsApproximatesStops() throws {
        let space = try #require(CGColorSpace(name: CGColorSpace.extendedSRGB))
        let start = try #require(blackToWhite.color(at: 0, using: space))
        let end = try #require(blackToWhite.color(at: 1, using: space))
        // Start is near white (bright), end is near black (dark).
        let startBrightness = try #require(start.brightness)
        let endBrightness = try #require(end.brightness)
        #expect(startBrightness > endBrightness)
    }

    @Test func colorAtReturnsNilForEmptyGradient() {
        #expect(IceGradient().color(at: 0.5) == nil)
    }

    @Test func colorAtUsingDefaultDisplayP3Space() {
        // The single-argument overload resolves the extended Display P3 space.
        #expect(blackToWhite.color(at: 0.5) != nil)
    }

    @Test func averageColorIgnoringAlphaForcesOpaque() throws {
        let faded = blackToWhite.withAlpha(0.5)
        let average = try #require(faded.averageColor(option: .ignoreAlpha))
        let components = try #require(average.components)
        #expect(abs(components[3] - 1) < 0.01)
    }

    @Test func averageColorHonorsExplicitRGBColorSpace() throws {
        let space = try #require(CGColorSpace(name: CGColorSpace.extendedSRGB))
        #expect(blackToWhite.averageColor(using: space) != nil)
    }

    @Test func averageColorNilForEmptyGradient() {
        #expect(IceGradient().averageColor() == nil)
    }

    @Test func averageColorNonNilForPopulatedGradient() {
        #expect(blackToWhite.averageColor() != nil)
    }

    @Test func codableRoundTripPreservesStopCount() throws {
        let data = try JSONEncoder().encode(blackToWhite)
        let decoded = try JSONDecoder().decode(IceGradient.self, from: data)
        #expect(decoded.stops.count == 2)
    }
}
