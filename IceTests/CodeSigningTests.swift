//
//  CodeSigningTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

/// Covers the Team Identifier lookup that decides whether the menu bar item
/// XPC service can enforce its `isFromSameTeam` peer requirement.
///
/// The concrete value depends on how the host was signed (a Developer ID
/// build has a team; an ad-hoc local build does not), so these tests assert
/// the invariants that must hold either way.
struct CodeSigningTests {
    @Test func hasTeamIdentifierAgreesWithTheLookup() {
        #expect(CodeSigning.hasTeamIdentifier == (CodeSigning.teamIdentifier != nil))
    }

    @Test func teamIdentifierIsNeverEmpty() {
        // The implementation deliberately maps an empty team to nil, so an
        // empty string must never surface.
        if let team = CodeSigning.teamIdentifier {
            #expect(!team.isEmpty)
        }
    }

    @Test func teamIdentifierIsStableAcrossCalls() {
        // Nothing is cached, so repeated lookups must still agree.
        #expect(CodeSigning.teamIdentifier == CodeSigning.teamIdentifier)
        #expect(CodeSigning.hasTeamIdentifier == CodeSigning.hasTeamIdentifier)
    }

    @Test func teamIdentifierHasNoWhitespace() {
        // A Team Identifier is an opaque alphanumeric string; whitespace would
        // mean we read the wrong signing-information field.
        if let team = CodeSigning.teamIdentifier {
            #expect(team.rangeOfCharacter(from: .whitespacesAndNewlines) == nil)
        }
    }
}
