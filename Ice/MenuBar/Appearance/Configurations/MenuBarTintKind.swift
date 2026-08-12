//
//  MenuBarTintKind.swift
//  Ice
//

import DragonKit
import SwiftUI

/// A type that specifies how the menu bar is tinted.
enum MenuBarTintKind: Int, CaseIterable, Codable, Identifiable {
    /// The menu bar is not tinted.
    case noTint = 0
    /// The menu bar is tinted with a solid color.
    case solid = 1
    /// The menu bar is tinted with a gradient.
    case gradient = 2

    var id: Int { rawValue }

    /// The name shown in the tint picker.
    @MainActor var localized: String {
        switch self {
        case .noTint: L("app.common.none")
        case .solid: L("app.appearance.tint.solid")
        case .gradient: L("app.appearance.tint.gradient")
        }
    }
}
