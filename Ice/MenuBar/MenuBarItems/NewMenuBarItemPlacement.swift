//
//  NewMenuBarItemPlacement.swift
//  Ice
//

import Foundation

/// The rules that decide which menu bar items were newly created, and which
/// items Ice should remember having seen.
///
/// macOS gives every new status item the leftmost slot in the menu bar, which
/// falls past Ice's always-hidden divider, so a newly installed app's icon is
/// invisible until the user goes looking for it. Ice remembers the items it has
/// already seen so it can move only the genuinely new ones.
///
/// These rules work on tags rather than items because ``MenuBarItem``'s
/// initializers are private: a tag is directly constructible, so the decisions
/// that drive placement can be tested without a live menu bar.
enum NewMenuBarItemPlacement {
    /// Returns a Boolean value that indicates whether the item identified by
    /// `tag` may be placed automatically.
    ///
    /// Items macOS pins in place, items that cannot be hidden, Ice's own control
    /// items and spacers are all excluded, as is anything whose identity is not
    /// durable. A UUID namespace is minted per process launch and cached by
    /// window ID, so the same item can be tagged differently after a relaunch;
    /// moving such an item on every launch is worse than leaving it alone. That
    /// test also covers system clones, which are the UUID namespace with a known
    /// title. An empty title is the same problem for titles: an untitled item
    /// cannot be told apart from its siblings in the same namespace.
    static func isPlaceable(_ tag: MenuBarItemTag) -> Bool {
        tag.isMovable &&
        tag.canBeHidden &&
        !tag.isControlItem &&
        !tag.isSpacerItem &&
        !tag.namespace.isUUID &&
        !tag.title.isEmpty
    }

    /// Returns the tags of the items that appear to have been newly created.
    ///
    /// `orderedTags` must run left to right across the menu bar. The landing
    /// zone is the prefix before the leftmost control item — the always-hidden
    /// divider when that section is enabled, the hidden divider when it is not —
    /// because that is where macOS puts a brand-new item. The walk stops at the
    /// first placeable tag it already knows: everything beyond that point is
    /// sitting where the user left it, not in the slot handed to new items.
    ///
    /// That positional test is what makes "new" mean *newly created* rather than
    /// merely *unrecorded*. An item that Ice has never recorded because it lives
    /// on another Space is unrecorded too, but it is not in the landing zone.
    ///
    /// - Returns: The candidate tags, in left-to-right order, de-duplicated.
    ///   Empty if there is no control item, which means the read failed.
    static func candidateTags(
        in orderedTags: [MenuBarItemTag],
        known: Set<MenuBarItemTag>
    ) -> [MenuBarItemTag] {
        guard let boundary = orderedTags.firstIndex(where: { $0.isControlItem }) else {
            return []
        }
        var candidates = [MenuBarItemTag]()
        var alreadyCollected = Set<MenuBarItemTag>()
        for tag in orderedTags[..<boundary] {
            guard isPlaceable(tag) else {
                continue // Not our business; doesn't end the walk.
            }
            guard !known.contains(tag) else {
                break
            }
            if alreadyCollected.insert(tag).inserted {
                candidates.append(tag)
            }
        }
        return candidates
    }

    /// Returns the tags to add to the known set after a placement pass.
    ///
    /// Every placeable tag the pass saw is recorded, minus the candidates it
    /// identified, plus the candidates it verified as placed. A candidate whose
    /// move failed stays unknown so the next pass retries it; recording it would
    /// let one transient event failure permanently defeat placement for that
    /// icon.
    ///
    /// Subtracting only the candidates — rather than recording only what lies
    /// outside the landing zone — is what stops a delayed false positive. An
    /// unknown item sitting behind the item that stopped the walk is neither
    /// placed nor a candidate. Left unrecorded, it would become a candidate the
    /// day the blocking item's app quit and the walk ran further, dragging an
    /// item the user had deliberately parked out of the always-hidden section.
    static func tagsToRecord(
        seen orderedTags: [MenuBarItemTag],
        candidates: [MenuBarItemTag],
        placed: Set<MenuBarItemTag>
    ) -> Set<MenuBarItemTag> {
        Set(orderedTags.filter(isPlaceable))
            .subtracting(candidates)
            .union(placed)
    }

    /// Decodes a known-items set, or returns `nil` if the payload is unreadable.
    static func decodeKnownTags(from data: Data) -> Set<MenuBarItemTag>? {
        try? JSONDecoder().decode(Set<MenuBarItemTag>.self, from: data)
    }

    /// Encodes a known-items set for storage.
    static func encode(_ tags: Set<MenuBarItemTag>) -> Data? {
        try? JSONEncoder().encode(tags)
    }
}
