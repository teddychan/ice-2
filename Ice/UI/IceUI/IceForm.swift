//
//  IceForm.swift
//  Ice
//

import SwiftUI

/// A settings form built on the system's grouped `Form`, so panes adopt the
/// standard macOS inset-grouped appearance, fonts, and control sizing.
///
/// The `alignment`, `padding`, and `spacing` parameters are retained for source
/// compatibility with existing call sites; layout is now driven by `Form`.
struct IceForm<Content: View>: View {
    private let content: Content

    init(
        alignment: HorizontalAlignment = .center,
        padding: EdgeInsets = .iceFormDefaultPadding,
        spacing: CGFloat = .iceFormDefaultSpacing,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    init(
        alignment: HorizontalAlignment = .center,
        padding: CGFloat,
        spacing: CGFloat = .iceFormDefaultSpacing,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        Form {
            content
        }
        .formStyle(.grouped)
        .focusSection()
        .accessibilityElement(children: .contain)
    }
}

extension EdgeInsets {
    /// The default padding for an ``IceForm``.
    static let iceFormDefaultPadding: EdgeInsets = {
        var insets = EdgeInsets(all: 20)
        insets.top = 0
        return insets
    }()
}

extension CGFloat {
    /// The default spacing for an ``IceForm``.
    static let iceFormDefaultSpacing: CGFloat = 10
}
