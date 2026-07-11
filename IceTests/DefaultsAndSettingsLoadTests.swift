//
//  DefaultsAndSettingsLoadTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

/// These tests swap the process-wide `Defaults.store` to a throwaway suite, so
/// the suite is `.serialized` to prevent them from racing each other on that
/// shared seam. No other test touches `Defaults.store`.
@Suite(.serialized)
struct DefaultsAndSettingsLoadTests {
    /// Installs a fresh throwaway store, runs `body`, then restores the previous
    /// store and deletes the suite.
    private func withScratchStore(_ body: (UserDefaults) throws -> Void) rethrows {
        let name = "IceTests.defaults." + UUID().uuidString
        let scratch = UserDefaults(suiteName: name)!
        let previous = Defaults.store
        Defaults.store = scratch
        defer {
            Defaults.store = previous
            UserDefaults.standard.removePersistentDomain(forName: name)
        }
        try body(scratch)
    }

    @MainActor
    private func withScratchStore(_ body: (UserDefaults) async throws -> Void) async rethrows {
        let name = "IceTests.defaults." + UUID().uuidString
        let scratch = UserDefaults(suiteName: name)!
        let previous = Defaults.store
        Defaults.store = scratch
        defer {
            Defaults.store = previous
            UserDefaults.standard.removePersistentDomain(forName: name)
        }
        try await body(scratch)
    }

    // MARK: - Defaults wrapper

    @Test func typedAccessorsReadThroughStore() {
        withScratchStore { scratch in
            scratch.set("s", forKey: Defaults.Key.iceIcon.rawValue)
            scratch.set(3, forKey: Defaults.Key.showOnHoverDelay.rawValue)
            scratch.set(1.5, forKey: Defaults.Key.rehideInterval.rawValue)
            scratch.set(true, forKey: Defaults.Key.useIceBar.rawValue)
            scratch.set(Data("x".utf8), forKey: Defaults.Key.hotkeys.rawValue)

            #expect(Defaults.string(forKey: .iceIcon) == "s")
            #expect(Defaults.object(forKey: .iceIcon) as? String == "s")
            #expect(Defaults.integer(forKey: .showOnHoverDelay) == 3)
            #expect(Defaults.double(forKey: .rehideInterval) == 1.5)
            #expect(Defaults.bool(forKey: .useIceBar))
            #expect(Defaults.data(forKey: .hotkeys) == Data("x".utf8))
        }
    }

    @Test func setAndRemoveRoundTrip() {
        withScratchStore { _ in
            Defaults.set("hello", forKey: .iceIcon)
            #expect(Defaults.string(forKey: .iceIcon) == "hello")
            Defaults.removeObject(forKey: .iceIcon)
            #expect(Defaults.object(forKey: .iceIcon) == nil)
        }
    }

    @Test func arrayAndDictionaryAccessors() {
        withScratchStore { _ in
            Defaults.set(["a", "b"], forKey: .menuBarSpacers)
            Defaults.set(["k": 1], forKey: .sections)
            #expect(Defaults.array(forKey: .menuBarSpacers)?.count == 2)
            #expect(Defaults.stringArray(forKey: .menuBarSpacers) == ["a", "b"])
            #expect(Defaults.dictionary(forKey: .sections)?["k"] as? Int == 1)
        }
    }

    @Test func ifPresentAssignsOnlyWhenPresentAndTypeMatches() {
        withScratchStore { _ in
            var value = "default"
            Defaults.ifPresent(key: .iceIcon, assign: &value)
            #expect(value == "default") // absent → unchanged

            Defaults.set("stored", forKey: .iceIcon)
            Defaults.ifPresent(key: .iceIcon, assign: &value)
            #expect(value == "stored") // present → assigned
        }
    }

    @Test func ifPresentBodyRunsOnlyWhenPresent() {
        withScratchStore { _ in
            var ran = false
            Defaults.ifPresent(key: .rehideStrategy) { (_: Int) in ran = true }
            #expect(!ran)

            Defaults.set(2, forKey: .rehideStrategy)
            var captured: Int?
            Defaults.ifPresent(key: .rehideStrategy) { (value: Int) in captured = value }
            #expect(captured == 2)
        }
    }

    // MARK: - GeneralSettings load

    @MainActor
    @Test func generalSettingsLoadsStoredValues() async {
        await withScratchStore { scratch in
            scratch.set(false, forKey: Defaults.Key.showIceIcon.rawValue)
            scratch.set(true, forKey: Defaults.Key.useIceBar.rawValue)
            scratch.set(42.0, forKey: Defaults.Key.rehideInterval.rawValue)
            scratch.set(RehideStrategy.timed.rawValue, forKey: Defaults.Key.rehideStrategy.rawValue)
            scratch.set(IceBarLocation.iceIcon.rawValue, forKey: Defaults.Key.iceBarLocation.rawValue)
            scratch.set(IceBarAutoEnableMode.screensWithNotch.rawValue, forKey: Defaults.Key.iceBarAutoEnableMode.rawValue)

            let settings = GeneralSettings()
            settings.performSetup(with: AppState())
            // Let the @Published persistence sinks fire their initial values.
            try? await Task.sleep(for: .milliseconds(50))

            #expect(settings.showIceIcon == false)
            #expect(settings.useIceBar == true)
            #expect(settings.rehideInterval == 42.0)
            #expect(settings.rehideStrategy == .timed)
            #expect(settings.iceBarLocation == .iceIcon)
            #expect(settings.iceBarAutoEnableMode == .screensWithNotch)
        }
    }

    @MainActor
    @Test func generalSettingsPersistsChangesToStore() async {
        await withScratchStore { scratch in
            let settings = GeneralSettings()
            settings.performSetup(with: AppState())

            settings.useIceBar = true
            settings.rehideStrategy = .focusedApp
            try? await Task.sleep(for: .milliseconds(50))

            #expect(scratch.bool(forKey: Defaults.Key.useIceBar.rawValue))
            #expect(scratch.integer(forKey: Defaults.Key.rehideStrategy.rawValue) == RehideStrategy.focusedApp.rawValue)
        }
    }

    // MARK: - AdvancedSettings load

    @MainActor
    @Test func advancedSettingsLoadsStoredValues() async {
        await withScratchStore { scratch in
            scratch.set(false, forKey: Defaults.Key.enableAlwaysHiddenSection.rawValue)
            scratch.set(99.0, forKey: Defaults.Key.tempShowInterval.rawValue)
            scratch.set(SectionDividerStyle.chevron.rawValue, forKey: Defaults.Key.sectionDividerStyle.rawValue)

            let settings = AdvancedSettings()
            settings.performSetup(with: AppState())
            try? await Task.sleep(for: .milliseconds(50))

            #expect(settings.enableAlwaysHiddenSection == false)
            #expect(settings.tempShowInterval == 99.0)
            #expect(settings.sectionDividerStyle == .chevron)
        }
    }

    // MARK: - MenuBarTriggerSettings load

    @MainActor
    @Test func triggerSettingsDecodesStoredTriggers() async throws {
        try await withScratchStore { scratch in
            let trigger = MenuBarTrigger(
                id: UUID(),
                name: "Safari",
                createdAt: Date(timeIntervalSince1970: 0),
                condition: .frontmostApplication(bundleIdentifier: "com.apple.Safari"),
                action: .showHiddenSection,
                itemGroupID: nil
            )
            let data = try JSONEncoder().encode([trigger])
            scratch.set(data, forKey: Defaults.Key.menuBarTriggers.rawValue)

            let settings = MenuBarTriggerSettings()
            settings.performSetup(with: AppState())
            try? await Task.sleep(for: .milliseconds(50))

            #expect(settings.triggers.count == 1)
            #expect(settings.triggers.first?.bundleIdentifier == "com.apple.Safari")
        }
    }
}
