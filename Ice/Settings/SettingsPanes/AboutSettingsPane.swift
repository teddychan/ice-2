//
//  AboutSettingsPane.swift
//  Ice
//

import SwiftUI

struct AboutSettingsPane: View {
    @Environment(\.openURL) private var openURL

    private var acknowledgementsURL: URL {
        // swiftlint:disable:next force_unwrapping
        Bundle.main.url(forResource: "Acknowledgements", withExtension: "pdf")!
    }

    private var contributeURL: URL {
        URL(string: "https://github.com/teddychan/ice-2")!
    }

    private var issuesURL: URL {
        contributeURL.appendingPathComponent("issues")
    }

    var body: some View {
        IceForm {
            IceSection(options: .plain) {
                appIconAndCopyright
            }
            IceSection {
                linkRows
            }
        }
    }

    @ViewBuilder
    private var appIconAndCopyright: some View {
        VStack(spacing: 6) {
            if let nsImage = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128, height: 128)
            }

            Text("Ice 2")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Version \(Constants.versionString)")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(Constants.copyrightString)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var linkRows: some View {
        Button {
            openURL(contributeURL)
        } label: {
            Label("Support on GitHub", systemImage: "link")
        }

        Button {
            openURL(issuesURL)
        } label: {
            Label("Report a Bug", systemImage: "ladybug")
        }

        Button {
            NSWorkspace.shared.open(acknowledgementsURL)
        } label: {
            Label("Acknowledgements", systemImage: "doc.text")
        }
    }
}
