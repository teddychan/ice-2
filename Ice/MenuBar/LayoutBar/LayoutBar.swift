//
//  LayoutBar.swift
//  Ice
//

import SwiftUI

struct LayoutBar: View {
    private struct Representable: NSViewRepresentable {
        let appState: AppState
        let section: MenuBarSection.Name

        func makeNSView(context: Context) -> LayoutBarScrollView {
            LayoutBarScrollView(appState: appState, section: section)
        }

        func updateNSView(_ nsView: LayoutBarScrollView, context: Context) { }
    }

    @EnvironmentObject var appState: AppState
    @ObservedObject var imageCache: MenuBarItemImageCache

    let section: MenuBarSection.Name

    private var backgroundShape: some InsettableShape {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }

    var body: some View {
        mainContent
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .menuBarItemContainer(appState: appState)
            .containerShape(backgroundShape)
            .clipShape(backgroundShape)
            .contentShape([.interaction, .focusEffect], backgroundShape)
            .overlay {
                backgroundShape
                    .strokeBorder(.quaternary)
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        Representable(appState: appState, section: section)
    }
}
