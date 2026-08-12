//
//  IceMenu.swift
//  Ice
//

import SwiftUI

struct IceMenu<Title: View, Label: View, Content: View>: View {
    private let title: Title
    private let label: Label
    private let content: Content

    /// Creates a menu with the given content, title, and label.
    ///
    /// - Parameters:
    ///   - content: A group of menu items.
    ///   - title: A view to display inside the menu.
    ///   - label: A view to display as an external label for the menu.
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder title: () -> Title,
        @ViewBuilder label: () -> Label
    ) {
        self.title = title()
        self.label = label()
        self.content = content()
    }

    /// Creates a menu with the given content, title, and label key.
    ///
    /// - Parameters:
    ///   - label: An already-localized external label, normally `L("app.…")`. See
    ///     ``IcePicker`` for why this is a `String` and not a `LocalizedStringKey`.
    ///   - content: A group of menu items.
    ///   - title: A view to display inside the menu.
    init(
        _ label: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder title: () -> Title
    ) where Label == Text {
        self.init {
            content()
        } title: {
            title()
        } label: {
            Text(label)
        }
    }

    var body: some View {
        LabeledContent {
            Menu {
                content
                    .labelStyle(.titleAndIcon)
                    .toggleStyle(.automatic)
            } label: {
                title
            }
            .menuStyle(.button)
            .buttonStyle(.bordered)
            .labelsHidden()
            .fixedSize()
        } label: {
            label
        }
    }
}
