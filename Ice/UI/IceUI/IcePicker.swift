//
//  IcePicker.swift
//  Ice
//

import SwiftUI

struct IcePicker<Label: View, SelectionValue: Hashable, Content: View>: View {
    @Binding var selection: SelectionValue

    let label: Label
    let content: Content

    init(
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        self._selection = selection
        self.label = label()
        self.content = content()
    }

    /// - Parameter title: An already-localized title, normally `L("app.…")`. Deliberately a
    ///   `String` rather than a `LocalizedStringKey`: a key is resolved against the process's
    ///   preferred localizations, which are fixed at launch, so it would ignore the language
    ///   chosen in `LanguagePicker` until the next relaunch.
    init(
        _ title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) where Label == Text {
        self.init(selection: selection) {
            content()
        } label: {
            Text(title)
        }
    }

    var body: some View {
        LabeledContent {
            Picker(selection: $selection) {
                content
                    .labelStyle(.titleAndIcon)
                    .toggleStyle(.automatic)
            } label: {
                label
            }
            .pickerStyle(.menu)
            .buttonStyle(.bordered)
            .labelsHidden()
            .fixedSize()
        } label: {
            label
        }
    }
}
