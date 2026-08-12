//
//  PermissionsView.swift
//  Ice
//

import DragonKit
import SwiftUI

struct PermissionsView: View {
    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var manager: AppPermissions

    private var continueButtonText: String {
        if case .hasRequired = manager.permissionsState {
            L("app.permissions.continueLimited")
        } else {
            L("app.permissions.continue")
        }
    }

    private var continueButtonForegroundStyle: some ShapeStyle {
        switch manager.permissionsState {
        case .missing:
            AnyShapeStyle(.secondary)
        case .hasAll:
            AnyShapeStyle(.primary)
        case .hasRequired:
            AnyShapeStyle(Color("LimitedModeButtonColor"))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.vertical)

            permissionsStack

            footerView
                .padding(.vertical)
        }
        .padding(.horizontal)
        .frame(width: 550)
        .fixedSize()
        .onAppear {
            manager.refreshAllPermissions()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }
            manager.refreshAllPermissions()
        }
    }

    @ViewBuilder
    private var headerView: some View {
        Label {
            Text(L("DragonKit.pane.permissions"))
                .font(.system(size: 40, weight: .medium))
        } icon: {
            if let nsImage = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 85, height: 85)
            }
        }
    }

    @ViewBuilder
    private var explanationBox: some View {
        DragonSection {
            VStack {
                Text(L("app.permissions.intro"))
                    .fontWeight(.medium)
                Text(L("app.permissions.privacy"))
                    .bold()
                    .foregroundStyle(Color(red: 0.5, green: 0.75, blue: 1))
            }
            .padding()
        }
        .font(.title3)
    }

    @ViewBuilder
    private var permissionsStack: some View {
        VStack {
            explanationBox
            ForEach(manager.allPermissions) { permission in
                permissionBox(permission)
            }
        }
    }

    @ViewBuilder
    private var footerView: some View {
        HStack {
            quitButton
            recheckButton
            continueButton
        }
        .controlSize(.large)
    }

    @ViewBuilder
    private var quitButton: some View {
        Button {
            NSApp.terminate(nil)
        } label: {
            Text(L("app.permissions.quit"))
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var recheckButton: some View {
        Button {
            manager.refreshAllPermissions()
        } label: {
            Text(L("app.common.checkAgain"))
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var continueButton: some View {
        Button {
            appState.dismissWindow(.permissions)

            guard manager.permissionsState != .missing else {
                appState.performSetup(hasPermissions: false)
                return
            }

            appState.performSetup(hasPermissions: true)

            Task {
                appState.activate(withPolicy: .regular)
                appState.openWindow(.settings)
            }
        } label: {
            Text(continueButtonText)
                .frame(maxWidth: .infinity)
                .foregroundStyle(continueButtonForegroundStyle)
        }
        .disabled(manager.permissionsState == .missing)
    }

    @ViewBuilder
    private func permissionBox(_ permission: Permission) -> some View {
        DragonSection {
            VStack(spacing: 12) {
                Text(L(permission.title))
                    .font(.title.weight(.medium))
                    .underline()

                VStack(spacing: 2) {
                    Text(L("app.permissions.needsThisTo"))
                        .font(.title3)
                        .bold()

                    VStack(alignment: .leading) {
                        ForEach(permission.details, id: \.self) { detail in
                            HStack {
                                Text("•").bold()
                                Text(L(detail)).fontWeight(.medium)
                            }
                        }
                    }
                }

                Button {
                    permission.performRequest()
                    if !permission.mayRequireRelaunch {
                        Task {
                            await permission.waitForPermission()
                            appState.activate(withPolicy: .regular)
                            appState.openWindow(.permissions)
                        }
                    }
                } label: {
                    if permission.hasPermission {
                        Text(L("app.permissions.granted"))
                            .foregroundStyle(.green)
                    } else {
                        Text(L("app.permissions.grant"))
                    }
                }
                .allowsHitTesting(!permission.hasPermission)

                if permission.mayRequireRelaunch && !permission.hasPermission {
                    VStack(spacing: 6) {
                        Text(L("app.permissions.relaunchNote"))
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)

                        Button(L("app.common.relaunch")) {
                            appState.relaunch()
                        }
                    }
                }

                if !permission.isRequired {
                    CalloutBox(L("app.permissions.limitedMode.callout")) {
                        Image(systemName: "checkmark.shield")
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
        }
    }
}
