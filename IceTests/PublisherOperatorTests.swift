//
//  PublisherOperatorTests.swift
//  IceTests
//

import Combine
import Foundation
import Testing
@testable import Ice_2

/// Covers the custom Combine operators that Ice's reactive plumbing is
/// built on — settings observation, state invalidation, and event merging.
struct PublisherOperatorTests {
    /// Synchronously drains a publisher that emits on subscribe.
    private func collect<P: Publisher>(_ publisher: P) -> [P.Output] where P.Failure == Never {
        var output = [P.Output]()
        let cancellable = publisher.sink { output.append($0) }
        cancellable.cancel()
        return output
    }

    // MARK: replace

    @Test func replaceSubstitutesAFreshlyComputedElement() {
        var callCount = 0
        let result = collect([1, 2, 3].publisher.replace { () -> Int in
            callCount += 1
            return callCount
        })
        // The closure runs once per upstream element.
        #expect(result == [1, 2, 3])
        #expect(callCount == 3)
    }

    @Test func replaceWithSubstitutesAConstant() {
        #expect(collect([1, 2, 3].publisher.replace(with: "x")) == ["x", "x", "x"])
    }

    @Test func replacePreservesUpstreamElementCount() {
        #expect(collect(Empty<Int, Never>().replace(with: 0)).isEmpty)
    }

    // MARK: removeNil

    @Test func removeNilDropsNilElements() {
        let upstream = [1, nil, 2, nil, nil, 3].publisher
        #expect(collect(upstream.removeNil()) == [1, 2, 3])
    }

    @Test func removeNilOnAllNilProducesNothing() {
        let upstream = [Int?.none, nil].publisher
        #expect(collect(upstream.removeNil()).isEmpty)
    }

    // MARK: removeDuplicates for tuples

    @Test func removeDuplicatesComparesEveryTupleElement() {
        let subject = PassthroughSubject<(Int, String), Never>()
        var output = [(Int, String)]()
        let cancellable = subject.removeDuplicates().sink { output.append($0) }

        subject.send((1, "a"))
        subject.send((1, "a")) // fully duplicate - dropped
        subject.send((1, "b")) // second element differs - kept
        subject.send((2, "b")) // first element differs - kept
        subject.send((2, "b")) // fully duplicate - dropped
        cancellable.cancel()

        #expect(output.count == 3)
        #expect(output.map(\.0) == [1, 1, 2])
        #expect(output.map(\.1) == ["a", "b", "b"])
    }

    @Test func removeDuplicatesKeepsNonAdjacentRepeats() {
        // Only consecutive duplicates are removed.
        let subject = PassthroughSubject<(Int, Int), Never>()
        var output = [(Int, Int)]()
        let cancellable = subject.removeDuplicates().sink { output.append($0) }

        subject.send((1, 1))
        subject.send((2, 2))
        subject.send((1, 1))
        cancellable.cancel()

        #expect(output.count == 3)
    }

    // MARK: discardMerge

    @Test func discardMergeEmitsForEitherUpstream() {
        let ints = PassthroughSubject<Int, Never>()
        let strings = PassthroughSubject<String, Never>()
        var count = 0
        let cancellable = ints.discardMerge(strings).sink { _ in count += 1 }

        ints.send(1)
        strings.send("a")
        ints.send(2)
        strings.send("b")
        cancellable.cancel()

        #expect(count == 4)
    }

    @Test func discardMergeStopsAfterCancellation() {
        let ints = PassthroughSubject<Int, Never>()
        let strings = PassthroughSubject<String, Never>()
        var count = 0
        let cancellable = ints.discardMerge(strings).sink { _ in count += 1 }

        ints.send(1)
        cancellable.cancel()
        ints.send(2)
        strings.send("a")

        #expect(count == 1)
    }

    // MARK: mergeMap

    @Test func mergeMapFlattensAPublisherPerSequenceElement() {
        let result = collect(Just([1, 2, 3]).mergeMap { Just($0 * 2) })
        #expect(Set(result) == [2, 4, 6])
    }

    @Test func mergeMapOnEmptySequenceEmitsNothing() {
        #expect(collect(Just([Int]()).mergeMap { Just($0) }).isEmpty)
    }
}
