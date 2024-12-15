//
//  ObjectTrackingViw.swift
//  ChristmARsTree
//
//  Created by 福田陸弥 on 2024/12/13.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ObjectTrackingView: View {
    @Environment(AppModel.self) private var appModel

    private var rootEntity = Entity()

    var body: some View {
        RealityView { content in
            content.add(rootEntity)
        }
        .task {
            await appModel.startTracking(with: rootEntity)
        }
        .onDisappear() {
            for (_, visualization) in appModel.objectVisualizations {
                rootEntity.removeChild(visualization.entity)
            }

            appModel.objectVisualizations.removeAll()
        }
    }
}
