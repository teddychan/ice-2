//
//  PredicatesTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

struct PredicatesTests {
    @Test func nonThrowingInputPredicate() {
        let isEven = Predicates<Int>.predicate { $0 % 2 == 0 }
        #expect(isEven(4))
        #expect(!isEven(3))
    }

    @Test func throwingInputPredicate() throws {
        struct Boom: Error {}
        let predicate = Predicates<Int>.predicate { (value: Int) throws -> Bool in
            if value < 0 { throw Boom() }
            return value > 10
        }
        #expect(try predicate(20))
        #expect(try !predicate(5))
        #expect(throws: Boom.self) {
            _ = try predicate(-1)
        }
    }

    @Test func nonThrowingInputlessPredicateIgnoresInput() {
        let alwaysTrue = Predicates<String>.predicate { true }
        #expect(alwaysTrue("anything"))
        #expect(alwaysTrue(""))
    }

    @Test func throwingInputlessPredicateIgnoresInput() throws {
        struct Boom: Error {}
        var shouldThrow = false
        let predicate = Predicates<String>.predicate { () throws -> Bool in
            if shouldThrow { throw Boom() }
            return true
        }
        #expect(try predicate("input"))
        shouldThrow = true
        #expect(throws: Boom.self) {
            _ = try predicate("input")
        }
    }
}
