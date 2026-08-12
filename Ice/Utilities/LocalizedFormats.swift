//
//  LocalizedFormats.swift
//  Ice
//

import DragonKit
import Foundation

/// A duration rendered as "1 second" / "2.5 seconds" in the currently selected language.
///
/// Two keys rather than one with a plural rule: ``L(_:)`` is a `Localizable.strings` lookup and
/// has no `.stringsdict` plural handling. The singular/plural split is the only distinction the
/// English source and its six translations need for the two sliders that use this — a hover
/// delay and a temporary-show delay, both 0–60 seconds.
///
/// Lives here rather than in either pane because both the General and Advanced panes formatted
/// the same durations with their own private copy of the function, so the two could disagree
/// about the wording the moment one was edited.
@MainActor
func formattedSeconds(_ interval: TimeInterval) -> String {
    let key = interval == 1 ? "app.common.second" : "app.common.seconds"
    return String(format: L(key), interval.formatted())
}
