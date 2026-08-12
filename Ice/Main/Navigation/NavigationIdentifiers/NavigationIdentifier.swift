//
//  NavigationIdentifier.swift
//  Ice
//

import SwiftUI

/// A type that represents an identifier for a navigation destination.
protocol NavigationIdentifier: CaseIterable, Hashable, Identifiable, RawRepresentable {
    /// An icon for the identifier's navigation destination.
    var iconResource: IconResource { get }

    /// A localized description for the identifier's navigation destination.
    ///
    /// Resolved through DragonKit's ``L(_:)``, not `LocalizedStringKey`: a `LocalizedStringKey`
    /// is looked up against the process's preferred localizations, which are read once at
    /// launch, so it cannot follow a language chosen from `LanguagePicker` without a relaunch.
    @MainActor var localized: String { get }
}

extension NavigationIdentifier where ID == Int {
    var id: Int { hashValue }
}
