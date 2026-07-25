//
//  CGImageProcessingTests.swift
//  IceTests
//

import CoreGraphics
import Foundation
import Testing
@testable import Ice_2

/// Covers the pixel-processing logic behind menu bar item image capture
/// (transparency trimming) and the Ice Bar's average-color tinting.
struct CGImageProcessingTests {
    // MARK: Fixtures

    /// Creates an image by drawing into a premultiplied-first ARGB context.
    private func makeImage(width: Int, height: Int, draw: (CGContext) -> Void) throws -> CGImage {
        let context = try #require(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ))
        draw(context)
        return try #require(context.makeImage())
    }

    /// Creates a color in the same device RGB space the fixture contexts use,
    /// so drawing it doesn't run a color-space conversion and skew the
    /// expected component values.
    private func deviceColor(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
        CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [red, green, blue, alpha])!
    }

    /// Creates a fully transparent image.
    private func makeClearImage(width: Int = 10, height: Int = 10) throws -> CGImage {
        try makeImage(width: width, height: height) { _ in }
    }

    /// Creates an image filled entirely with the given color.
    private func makeFilledImage(width: Int = 10, height: Int = 10, color: CGColor) throws -> CGImage {
        try makeImage(width: width, height: height) { context in
            context.setFillColor(color)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    private func components(of color: CGColor) throws -> [CGFloat] {
        try #require(color.components)
    }

    // MARK: averageColor

    @Test func averageColorOfSolidFillIsThatColor() throws {
        let image = try makeFilledImage(color: deviceColor(1, 0, 0))
        let average = try #require(image.averageColor())
        let c = try components(of: average)
        #expect(abs(c[0] - 1) < 0.02)
        #expect(abs(c[1] - 0) < 0.02)
        #expect(abs(c[2] - 0) < 0.02)
        #expect(abs(c[3] - 1) < 0.02)
    }

    @Test func averageColorBlendsTwoHalves() throws {
        // Left half red, right half blue -> the average sits halfway between.
        let image = try makeImage(width: 10, height: 10) { context in
            context.setFillColor(deviceColor(1, 0, 0))
            context.fill(CGRect(x: 0, y: 0, width: 5, height: 10))
            context.setFillColor(deviceColor(0, 0, 1))
            context.fill(CGRect(x: 5, y: 0, width: 5, height: 10))
        }
        let average = try #require(image.averageColor())
        let c = try components(of: average)
        #expect(abs(c[0] - 0.5) < 0.05)
        #expect(abs(c[1] - 0) < 0.05)
        #expect(abs(c[2] - 0.5) < 0.05)
    }

    @Test func averageColorSkipsPixelsBelowAlphaThreshold() throws {
        // Half fully transparent, half opaque red.
        let image = try makeImage(width: 10, height: 10) { context in
            context.setFillColor(deviceColor(1, 0, 0))
            context.fill(CGRect(x: 5, y: 0, width: 5, height: 10))
        }

        // Threshold 0.5 excludes the transparent half, leaving pure red.
        let excluded = try #require(image.averageColor(alphaThreshold: 0.5))
        let excludedComponents = try components(of: excluded)
        #expect(abs(excludedComponents[0] - 1) < 0.05)
        #expect(abs(excludedComponents[3] - 1) < 0.05)

        // Threshold 0 includes every pixel, halving both red and alpha.
        let included = try #require(image.averageColor(alphaThreshold: 0))
        let includedComponents = try components(of: included)
        #expect(abs(includedComponents[0] - 0.5) < 0.05)
        #expect(abs(includedComponents[3] - 0.5) < 0.05)
    }

    @Test func averageColorIgnoreAlphaForcesOpaqueResult() throws {
        let image = try makeImage(width: 10, height: 10) { context in
            context.setFillColor(deviceColor(1, 1, 1))
            context.fill(CGRect(x: 0, y: 0, width: 5, height: 10))
        }
        let withAlpha = try #require(image.averageColor(alphaThreshold: 0))
        let ignoringAlpha = try #require(image.averageColor(alphaThreshold: 0, option: .ignoreAlpha))
        #expect(try components(of: withAlpha)[3] < 0.9)
        #expect(try abs(components(of: ignoringAlpha)[3] - 1) < 0.001)
    }

    @Test func averageColorIsNilWhenNoPixelClearsTheThreshold() throws {
        // A fully transparent capture has no contributing pixels. Returning a
        // color here would divide by zero and hand callers a NaN color they
        // can't tell apart from a real one.
        let image = try makeClearImage()
        #expect(image.averageColor() == nil)
        #expect(image.averageColor(option: .ignoreAlpha) == nil)
    }

    @Test func averageColorStillReportsAColorWhenOnePixelClearsTheThreshold() throws {
        // The zero-pixel guard must not swallow a legitimately sparse image.
        let image = try makeImage(width: 10, height: 10) { context in
            context.setFillColor(deviceColor(1, 0, 0))
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        let average = try #require(image.averageColor(alphaThreshold: 0.5))
        let c = try components(of: average)
        #expect(!c.contains { $0.isNaN })
        #expect(abs(c[0] - 1) < 0.05)
    }

    @Test func averageColorClampsOutOfRangeAlphaThreshold() throws {
        // Thresholds outside 0...1 are clamped rather than rejected.
        let image = try makeFilledImage(color: deviceColor(0, 1, 0))
        #expect(image.averageColor(alphaThreshold: -5) != nil)
        #expect(image.averageColor(alphaThreshold: 5) != nil)
    }

    @Test func averageColorUsesRequestedRGBColorSpace() throws {
        let image = try makeFilledImage(color: deviceColor(1, 0, 0))
        let p3 = try #require(CGColorSpace(name: CGColorSpace.displayP3))
        let average = try #require(image.averageColor(using: p3))
        #expect(average.colorSpace?.name == p3.name)
    }

    @Test func averageColorIgnoresNonRGBColorSpaceRequest() throws {
        // A non-RGB request falls back to an RGB space instead of failing.
        let image = try makeFilledImage(color: deviceColor(1, 0, 0))
        let gray = CGColorSpaceCreateDeviceGray()
        let average = try #require(image.averageColor(using: gray))
        #expect(average.colorSpace?.model == .rgb)
    }

    // MARK: trimmingTransparency

    @Test func trimmingRemovesTransparentBorderOnAllEdges() throws {
        // A 4x4 opaque block surrounded by transparency.
        let image = try makeImage(width: 10, height: 10) { context in
            context.setFillColor(deviceColor(0, 0, 1))
            context.fill(CGRect(x: 3, y: 3, width: 4, height: 4))
        }
        let trimmed = try #require(image.trimmingTransparency())
        #expect(trimmed.width == 4)
        #expect(trimmed.height == 4)
    }

    @Test func trimmingSingleEdgeLeavesOtherDimensionsIntact() throws {
        let image = try makeImage(width: 10, height: 10) { context in
            context.setFillColor(deviceColor(0, 0, 1))
            context.fill(CGRect(x: 3, y: 3, width: 4, height: 4))
        }
        let trimmedMinX = try #require(image.trimmingTransparency(around: [.minXEdge]))
        #expect(trimmedMinX.width == 7)
        #expect(trimmedMinX.height == 10)

        let trimmedMaxX = try #require(image.trimmingTransparency(around: [.maxXEdge]))
        #expect(trimmedMaxX.width == 7)
        #expect(trimmedMaxX.height == 10)
    }

    @Test func trimmingEmptyEdgeSetReturnsImageUnchanged() throws {
        let image = try makeImage(width: 10, height: 10) { context in
            context.setFillColor(deviceColor(0, 0, 1))
            context.fill(CGRect(x: 3, y: 3, width: 4, height: 4))
        }
        let trimmed = try #require(image.trimmingTransparency(around: []))
        #expect(trimmed.width == 10)
        #expect(trimmed.height == 10)
    }

    @Test func trimmingFullyOpaqueImageIsANoOp() throws {
        let image = try makeFilledImage(color: deviceColor(1, 1, 1))
        let trimmed = try #require(image.trimmingTransparency())
        #expect(trimmed.width == 10)
        #expect(trimmed.height == 10)
    }

    @Test func trimmingFullyTransparentImageReturnsNil() throws {
        // Nothing opaque to anchor an inset to, so trimming can't produce an image.
        let image = try makeClearImage()
        #expect(image.trimmingTransparency() == nil)
    }

    @Test func trimmingIsSkippedWhenAlphaThresholdIsOpaque() throws {
        // A threshold of 1 or more makes every pixel "transparent", so the
        // guard bails out and hands back the original image untouched.
        let image = try makeClearImage()
        let trimmed = try #require(image.trimmingTransparency(alphaThreshold: 1))
        #expect(trimmed.width == 10)
        #expect(trimmed.height == 10)
    }

    // MARK: isTransparent

    @Test func fullyTransparentImageIsTransparent() throws {
        #expect(try makeClearImage().isTransparent())
    }

    @Test func imageWithAnyOpaquePixelIsNotTransparent() throws {
        let image = try makeImage(width: 10, height: 10) { context in
            context.setFillColor(deviceColor(1, 1, 1))
            context.fill(CGRect(x: 9, y: 9, width: 1, height: 1))
        }
        #expect(!image.isTransparent())
    }

    @Test func isTransparentHonorsAlphaThreshold() throws {
        // Faint pixels count as transparent only once the threshold exceeds them.
        let image = try makeFilledImage(color: deviceColor(1, 1, 1, 0.25))
        #expect(!image.isTransparent(alphaThreshold: 0))
        #expect(image.isTransparent(alphaThreshold: 0.5))
    }

    @Test func isTransparentReturnsFalseWhenThresholdIsOpaque() throws {
        // A threshold of 1 fails the guard, which reports "not transparent".
        #expect(!(try makeClearImage().isTransparent(alphaThreshold: 1)))
    }
}
