//
//  ChristmARsTreeApp.swift
//  ChristmARsTree
//
//  Created by 福田陸弥 on 2024/12/13.
//

import SwiftUI

@main
struct ChristmARsTreeApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .frame(width: 400,
                       height: 200)
                .task {
                    await appModel.referenceObjectLoader.loadReferenceObjects()
                }

        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ObjectTrackingView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed),
                        in: .mixed)
     }
}
