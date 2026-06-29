//
//  IceSection.swift
//  Ice
//

import SwiftUI

struct IceSectionOptions: OptionSet {
    let rawValue: Int

    static let isBordered = IceSectionOptions(rawValue: 1 << 0)
    static let hasDividers = IceSectionOptions(rawValue: 1 << 1)

    static let plain: IceSectionOptions = []
    static let `default`: IceSectionOptions = [.isBordered, .hasDividers]
}

/// A settings section built on the system's `Section`, so it adopts the
/// standard grouped `Form` appearance (inset box, row separators, header style).
///
/// The `spacing` and `options` parameters are retained for source compatibility;
/// grouping and dividers are now provided by the system grouped `Form`.
struct IceSection<Header: View, Content: View, Footer: View>: View {
    private let header: Header
    private let content: Content
    private let footer: Footer

    init(
        spacing: CGFloat = .iceSectionDefaultSpacing,
        options: IceSectionOptions = .default,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.header = header()
        self.content = content()
        self.footer = footer()
    }

    init(
        spacing: CGFloat = .iceSectionDefaultSpacing,
        options: IceSectionOptions = .default,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) where Header == EmptyView {
        self.init(spacing: spacing, options: options) {
            EmptyView()
        } content: {
            content()
        } footer: {
            footer()
        }
    }

    init(
        spacing: CGFloat = .iceSectionDefaultSpacing,
        options: IceSectionOptions = .default,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) where Footer == EmptyView {
        self.init(spacing: spacing, options: options) {
            header()
        } content: {
            content()
        } footer: {
            EmptyView()
        }
    }

    init(
        spacing: CGFloat = .iceSectionDefaultSpacing,
        options: IceSectionOptions = .default,
        @ViewBuilder content: () -> Content
    ) where Header == EmptyView, Footer == EmptyView {
        self.init(spacing: spacing, options: options) {
            EmptyView()
        } content: {
            content()
        } footer: {
            EmptyView()
        }
    }

    init(
        _ title: LocalizedStringKey,
        spacing: CGFloat = .iceSectionDefaultSpacing,
        options: IceSectionOptions = .default,
        @ViewBuilder content: () -> Content
    ) where Header == Text, Footer == EmptyView {
        self.init(spacing: spacing, options: options) {
            Text(title)
        } content: {
            content()
        }
    }

    var body: some View {
        Section {
            content
        } header: {
            header
        } footer: {
            footer
        }
    }
}

extension CGFloat {
    /// The default spacing for an ``IceSection``.
    static let iceSectionDefaultSpacing: CGFloat = 11
}
