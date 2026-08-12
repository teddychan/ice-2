//
//  SettingsEnumsTests.swift
//  IceTests
//

import Foundation
import Testing
@testable import Ice_2

struct SettingsEnumsTests {
    @MainActor
    @Test func rehideStrategyMetadata() {
        #expect(RehideStrategy.allCases.map(\.rawValue) == [0, 1, 2])
        #expect(RehideStrategy.smart.id == 0)
        #expect(RehideStrategy(rawValue: 1) == .timed)
        withEnglish {
            #expect(RehideStrategy.smart.localized == "Smart")
            #expect(RehideStrategy.timed.localized == "Timed")
            #expect(RehideStrategy.focusedApp.localized == "Focused app")
        }
    }

    @MainActor
    @Test func iceBarAutoEnableModeMetadata() {
        #expect(IceBarAutoEnableMode.allCases.map(\.rawValue) == [0, 1])
        #expect(IceBarAutoEnableMode.screensWithNotch.id == 1)
        withEnglish {
            #expect(IceBarAutoEnableMode.screenWidth.localized == "Screen width")
            #expect(IceBarAutoEnableMode.screensWithNotch.localized == "Screen notch")
        }
    }

    @MainActor
    @Test func iceBarLocationMetadata() {
        #expect(IceBarLocation.allCases.map(\.rawValue) == [0, 1, 2])
        #expect(IceBarLocation.iceIcon.id == 2)
        withEnglish {
            #expect(IceBarLocation.dynamic.localized == "Dynamic")
            #expect(IceBarLocation.mousePointer.localized == "Mouse pointer")
            #expect(IceBarLocation.iceIcon.localized == "Ice 2 icon")
        }
    }

    @MainActor
    @Test func sectionDividerStyleMetadata() {
        #expect(SectionDividerStyle.allCases.map(\.rawValue) == [0, 1])
        #expect(SectionDividerStyle.chevron.id == 1)
        withEnglish {
            #expect(SectionDividerStyle.noDivider.localized == "None")
            #expect(SectionDividerStyle.chevron.localized == "Chevron")
        }
    }

    @Test func rawValueInitRejectsOutOfRange() {
        #expect(RehideStrategy(rawValue: 99) == nil)
        #expect(IceBarLocation(rawValue: -1) == nil)
        #expect(SectionDividerStyle(rawValue: 5) == nil)
    }
}
