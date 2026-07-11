//
//  SettingsEnumsTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

struct SettingsEnumsTests {
    @Test func rehideStrategyMetadata() {
        #expect(RehideStrategy.allCases.map(\.rawValue) == [0, 1, 2])
        #expect(RehideStrategy.smart.id == 0)
        #expect(RehideStrategy(rawValue: 1) == .timed)
        #expect(RehideStrategy.smart.localized == "Smart")
        #expect(RehideStrategy.timed.localized == "Timed")
        #expect(RehideStrategy.focusedApp.localized == "Focused app")
    }

    @Test func iceBarAutoEnableModeMetadata() {
        #expect(IceBarAutoEnableMode.allCases.map(\.rawValue) == [0, 1])
        #expect(IceBarAutoEnableMode.screensWithNotch.id == 1)
        #expect(IceBarAutoEnableMode.screenWidth.localized == "Screen width")
        #expect(IceBarAutoEnableMode.screensWithNotch.localized == "Screen notch")
    }

    @Test func iceBarLocationMetadata() {
        #expect(IceBarLocation.allCases.map(\.rawValue) == [0, 1, 2])
        #expect(IceBarLocation.iceIcon.id == 2)
        #expect(IceBarLocation.dynamic.localized == "Dynamic")
        #expect(IceBarLocation.mousePointer.localized == "Mouse pointer")
        #expect(IceBarLocation.iceIcon.localized == "Ice 2 icon")
    }

    @Test func sectionDividerStyleMetadata() {
        #expect(SectionDividerStyle.allCases.map(\.rawValue) == [0, 1])
        #expect(SectionDividerStyle.chevron.id == 1)
        #expect(SectionDividerStyle.noDivider.localized == "None")
        #expect(SectionDividerStyle.chevron.localized == "Chevron")
    }

    @Test func rawValueInitRejectsOutOfRange() {
        #expect(RehideStrategy(rawValue: 99) == nil)
        #expect(IceBarLocation(rawValue: -1) == nil)
        #expect(SectionDividerStyle(rawValue: 5) == nil)
    }
}
