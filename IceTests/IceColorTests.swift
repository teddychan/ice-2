//
//  IceColorTests.swift
//  IceTests
//

import CoreGraphics
import Foundation
import Testing
@testable import Ice_2

struct IceColorTests {
    private func srgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
        CGColor(srgbRed: r, green: g, blue: b, alpha: a)
    }

    @Test func equalColorsAreEqual() {
        let a = IceColor(cgColor: srgb(0.2, 0.4, 0.6))
        let b = IceColor(cgColor: srgb(0.2, 0.4, 0.6))
        #expect(a == b)
    }

    @Test func codableRoundTripPreservesComponents() throws {
        let original = IceColor(cgColor: srgb(0.25, 0.5, 0.75, 0.8))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(IceColor.self, from: data)

        let originalComponents = original.cgColor.components ?? []
        let decodedComponents = decoded.cgColor.components ?? []
        #expect(originalComponents.count == decodedComponents.count)
        for (lhs, rhs) in zip(originalComponents, decodedComponents) {
            #expect(abs(lhs - rhs) < 0.0001)
        }
    }

    @Test func decodingInvalidICCDataThrows() throws {
        // Valid JSON shape, but the color-space payload is not a real ICC profile.
        let json = """
        {"components":[1,0,0,1],"colorSpace":"\(Data("not-icc".utf8).base64EncodedString())"}
        """
        let data = Data(json.utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(IceColor.self, from: data)
        }
    }
}
