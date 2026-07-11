//
//  AppearanceConfigTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

struct AppearanceConfigTests {
    // MARK: MenuBarEndCap

    @Test func endCapRawValuesAndCodable() throws {
        #expect(MenuBarEndCap.square.rawValue == 0)
        #expect(MenuBarEndCap.round.rawValue == 1)
        #expect(MenuBarEndCap.allCases.count == 2)
        for cap in MenuBarEndCap.allCases {
            let data = try JSONEncoder().encode(cap)
            #expect(try JSONDecoder().decode(MenuBarEndCap.self, from: data) == cap)
        }
    }

    // MARK: MenuBarShapeKind / TintKind

    @Test func shapeKindMetadata() {
        #expect(MenuBarShapeKind.allCases.map(\.rawValue) == [0, 1, 2])
        #expect(MenuBarShapeKind.split.id == 2)
        #expect(MenuBarShapeKind.noShape.localized == "None")
        #expect(MenuBarShapeKind.full.localized == "Full")
        #expect(MenuBarShapeKind.split.localized == "Split")
    }

    @Test func tintKindMetadata() {
        #expect(MenuBarTintKind.allCases.map(\.rawValue) == [0, 1, 2])
        #expect(MenuBarTintKind.gradient.id == 2)
        #expect(MenuBarTintKind.noTint.localized == "None")
        #expect(MenuBarTintKind.solid.localized == "Solid")
        #expect(MenuBarTintKind.gradient.localized == "Gradient")
    }

    // MARK: Full shape info

    @Test func fullShapeHasRoundedShape() {
        #expect(MenuBarFullShapeInfo(leadingEndCap: .round, trailingEndCap: .square).hasRoundedShape)
        #expect(MenuBarFullShapeInfo(leadingEndCap: .square, trailingEndCap: .round).hasRoundedShape)
        #expect(!MenuBarFullShapeInfo(leadingEndCap: .square, trailingEndCap: .square).hasRoundedShape)
    }

    @Test func fullShapeDefaultIsRounded() {
        #expect(MenuBarFullShapeInfo.default.leadingEndCap == .round)
        #expect(MenuBarFullShapeInfo.default.trailingEndCap == .round)
        #expect(MenuBarFullShapeInfo.default.hasRoundedShape)
    }

    @Test func fullShapeCodableRoundTrip() throws {
        let info = MenuBarFullShapeInfo(leadingEndCap: .square, trailingEndCap: .round)
        let data = try JSONEncoder().encode(info)
        #expect(try JSONDecoder().decode(MenuBarFullShapeInfo.self, from: data) == info)
    }

    // MARK: Split shape info

    @Test func splitShapeHasRoundedShapeWhenEitherSideIsRounded() {
        let squareSide = MenuBarFullShapeInfo(leadingEndCap: .square, trailingEndCap: .square)
        let roundSide = MenuBarFullShapeInfo(leadingEndCap: .round, trailingEndCap: .square)
        #expect(!MenuBarSplitShapeInfo(leading: squareSide, trailing: squareSide).hasRoundedShape)
        #expect(MenuBarSplitShapeInfo(leading: roundSide, trailing: squareSide).hasRoundedShape)
        #expect(MenuBarSplitShapeInfo(leading: squareSide, trailing: roundSide).hasRoundedShape)
    }

    @Test func splitShapeDefaultIsRounded() {
        #expect(MenuBarSplitShapeInfo.default.hasRoundedShape)
    }

    @Test func splitShapeCodableRoundTrip() throws {
        let info = MenuBarSplitShapeInfo.default
        let data = try JSONEncoder().encode(info)
        #expect(try JSONDecoder().decode(MenuBarSplitShapeInfo.self, from: data) == info)
    }
}
