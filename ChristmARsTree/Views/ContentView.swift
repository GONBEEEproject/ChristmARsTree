//
//  ContentView.swift
//  ChristmARsTree
//
//  Created by 福田陸弥 on 2024/12/13.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if appModel.canEnterImmersiveSpace {
                VStack {
                    Text("ChristmARs Tree")
                        .font(.title)
                    Spacer()

                    if appModel.immersiveSpaceState == .open {
                        Group {
                            Text("Searching")
                        }
                    }

                    ToggleImmersiveSpaceButton()
                }
                .padding()
            }
        }
        .padding()
        .onChange(of: scenePhase,
                  initial: true)
        {
            print("HomeView scene phase: \(scenePhase)")
            if scenePhase == .active {
                Task {
                    // When returning from the background, check if the authorization has changed.
                    await appModel.queryWorldSensingAuthorization()
                }
            } else {
                // Make sure to leave the immersive space if this view is no longer active
                // - such as when a person closes this view - otherwise they may be stuck
                // in the immersive space without the controls this view provides.
                if appModel.immersiveSpaceState == .open {
                    Task {
                        await dismissImmersiveSpace()
                    }
                }
            }
        }
        .onChange(of: appModel.providersStoppedWithError, { _, providersStoppedWithError in
            // Immediately close the immersive space if an error occurs.
            if providersStoppedWithError {
                if appModel.immersiveSpaceState == .open {
                    Task {
                        await dismissImmersiveSpace()
                    }
                }

                appModel.providersStoppedWithError = false
            }
        })
        .task {
            // Ask for authorization before a person attempts to open the immersive space.
            // This gives the app opportunity to respond gracefully if authorization isn't granted.
            if appModel.allRequiredProvidersAreSupported {
                await appModel.requestWorldSensingAuthorization()
            }
        }
//        .task {
//            // Start monitoring for changes in authorization, in case a person brings the
//            // Settings app to the foreground and changes authorizations there.
//            await appModel.monitorSessionEvents()
//        }
    }
}

#Preview(windowStyle: .automatic) {
    let appModel = AppModel()

    ContentView()
        .environment(appModel)
}
