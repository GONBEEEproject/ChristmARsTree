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
                    await appModel.queryWorldSensingAuthorization()
                }
            } else {
                if appModel.immersiveSpaceState == .open {
                    Task {
                        await dismissImmersiveSpace()
                    }
                }
            }
        }
        .onChange(of: appModel.providersStoppedWithError, { _, providersStoppedWithError in
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
            if appModel.allRequiredProvidersAreSupported {
                await appModel.requestWorldSensingAuthorization()
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    let appModel = AppModel()

    ContentView()
        .environment(appModel)
}
