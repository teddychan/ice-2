//
//  IceBarLocation.swift
//  Ice
//

import DragonKit
import SwiftUI

/// Locations where the Ice Bar can appear.
enum IceBarLocation: Int, CaseIterable, Identifiable {
    /// The Ice Bar will appear in different locations based on context.
    case dynamic = 0

    /// The Ice Bar will appear centered below the mouse pointer.
    case mousePointer = 1

    /// The Ice Bar will appear centered below the Ice icon.
    case iceIcon = 2

    var id: Int { rawValue }

    /// The name shown in the Ice 2 Bar location picker.
    @MainActor var localized: String {
        switch self {
        case .dynamic: L("app.general.location.dynamic")
        case .mousePointer: L("app.general.location.mousePointer")
        case .iceIcon: L("app.general.location.iceIcon")
        }
    }
}
