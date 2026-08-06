//
//  MenuBarItemImageCacheTests.swift
//  IceTests
//

import Testing
@testable import Ice_2

/// Pins which settings pane the item and image caches refresh for.
///
/// This is the regression these tests exist for. Both caches were gated on the pane that
/// renders the layout bar, written as `.menuBarLayout`. The 2.8.0 settings redesign
/// replaced that case with `.appearance` and `.layout`, and the rename sent both gates to
/// `.appearance` — the one pane that displays no item images. The caches then refreshed
/// only while the user was on a pane that showed nothing, and never while they watched the
/// layout bar. A capture that failed once stayed on screen as a lettered placeholder for as
/// long as the Layout pane was open, and applying a profile could not repaint it.
///
/// Nothing in the type system connects "the pane the user is on" to "the pane that draws
/// item images", so the constant carries that meaning and these tests hold it in place.
struct MenuBarItemImageCachePaneTests {
    @Test func theImageRenderingPaneIsTheLayoutPane() {
        // If a redesign renames or reorders the panes again, this fails first and names
        // the reason, instead of the layout bar quietly going stale.
        #expect(SettingsNavigationIdentifier.rendersMenuBarItemImages == .layout)
    }

    @Test func updatesWhileTheLayoutPaneIsShowing() {
        #expect(MenuBarItemImageCache.shouldUpdateCache(
            isIceBarPresented: false,
            isSearchPresented: false,
            isAppFrontmost: true,
            isSettingsPresented: true,
            settingsIdentifier: .layout
        ))
    }

    @Test func doesNotUpdateForPanesThatShowNoItemImages() {
        // `.appearance` is called out by name: it is what the broken gate pointed at, and
        // a fix that simply widened the gate to "any settings pane" would pass the test
        // above while still capturing for panes nobody can see the result on.
        for identifier in [SettingsNavigationIdentifier.appearance, .general, .about] {
            #expect(!MenuBarItemImageCache.shouldUpdateCache(
                isIceBarPresented: false,
                isSearchPresented: false,
                isAppFrontmost: true,
                isSettingsPresented: true,
                settingsIdentifier: identifier
            ))
        }
    }

    @Test func doesNotUpdateForABackgroundedSettingsWindow() {
        #expect(!MenuBarItemImageCache.shouldUpdateCache(
            isIceBarPresented: false,
            isSearchPresented: false,
            isAppFrontmost: false,
            isSettingsPresented: true,
            settingsIdentifier: .layout
        ))
    }

    @Test func theIceBarAndSearchPanelNeedNoSettingsWindow() {
        // Both draw item images on their own, so neither depends on the settings pane —
        // the identifier below is one that otherwise blocks the update.
        #expect(MenuBarItemImageCache.shouldUpdateCache(
            isIceBarPresented: true,
            isSearchPresented: false,
            isAppFrontmost: false,
            isSettingsPresented: false,
            settingsIdentifier: .about
        ))
        #expect(MenuBarItemImageCache.shouldUpdateCache(
            isIceBarPresented: false,
            isSearchPresented: true,
            isAppFrontmost: false,
            isSettingsPresented: false,
            settingsIdentifier: .about
        ))
    }

    @Test func nothingOnScreenMeansNoUpdate() {
        #expect(!MenuBarItemImageCache.shouldUpdateCache(
            isIceBarPresented: false,
            isSearchPresented: false,
            isAppFrontmost: true,
            isSettingsPresented: false,
            settingsIdentifier: .layout
        ))
    }
}

/// Pins which sections get captured for a given presentation state.
struct MenuBarItemImageCacheSectionsTests {
    @Test func settingsShowsEverySection() {
        let sections = MenuBarItemImageCache.sectionsNeedingDisplay(
            isSettingsPresented: true,
            isSearchPresented: false,
            isIceBarPresented: false,
            iceBarSection: nil
        )
        // The layout bar draws all three at once, so a partial capture leaves one of them
        // rendering placeholders.
        #expect(sections == MenuBarSection.Name.allCases)
    }

    @Test func searchShowsEverySection() {
        let sections = MenuBarItemImageCache.sectionsNeedingDisplay(
            isSettingsPresented: false,
            isSearchPresented: true,
            isIceBarPresented: false,
            iceBarSection: nil
        )
        #expect(sections == MenuBarSection.Name.allCases)
    }

    @Test func theIceBarNeedsOnlyTheSectionItIsShowing() {
        let sections = MenuBarItemImageCache.sectionsNeedingDisplay(
            isSettingsPresented: false,
            isSearchPresented: false,
            isIceBarPresented: true,
            iceBarSection: .hidden
        )
        #expect(sections == [.hidden])
    }

    @Test func settingsWinsOverTheIceBar() {
        // Both can be open at once; the settings window needs all three regardless of
        // which single section the Ice Bar happens to be showing.
        let sections = MenuBarItemImageCache.sectionsNeedingDisplay(
            isSettingsPresented: true,
            isSearchPresented: false,
            isIceBarPresented: true,
            iceBarSection: .alwaysHidden
        )
        #expect(sections == MenuBarSection.Name.allCases)
    }

    @Test func anIceBarWithNoCurrentSectionNeedsNothing() {
        let sections = MenuBarItemImageCache.sectionsNeedingDisplay(
            isSettingsPresented: false,
            isSearchPresented: false,
            isIceBarPresented: true,
            iceBarSection: nil
        )
        #expect(sections.isEmpty)
    }

    @Test func nothingOnScreenNeedsNothing() {
        let sections = MenuBarItemImageCache.sectionsNeedingDisplay(
            isSettingsPresented: false,
            isSearchPresented: false,
            isIceBarPresented: false,
            iceBarSection: nil
        )
        #expect(sections.isEmpty)
    }
}
