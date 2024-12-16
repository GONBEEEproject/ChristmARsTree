//
//  ObjectAnchorVisualization.swift
//  ChristmARsTree
//
//  Created by 福田陸弥 on 2024/12/13.
//

import ARKit
import RealityKit
import RealityKitContent

@MainActor
class ObjectAnchorVisualization {
    enum ObjectType: String {
        case VisionProCase
        case ChristmasBlack
    }

    var entity: Entity
    var type: ObjectType?

    private var appModel: AppModel

    init(
        for anchor: ObjectAnchor,
        withModel model: Entity? = nil,
        appModel: AppModel
    ) async {
        self.appModel = appModel

        guard let model else {
            print("Unable to find Reference Object model")
            entity = Entity()

            return
        }

        switch model.name {
        case ObjectType.VisionProCase.rawValue:
            self.type = .VisionProCase
        case ObjectType.ChristmasBlack.rawValue:
            self.type = .ChristmasBlack
        default:
            fatalError(
                "Attempted to create ObjectAnchorVisualization for unknown ObjectType"
            )
        }

        let entity = Entity()

        guard let type else {
            self.entity = entity

            return
        }

        switch type {
        case .VisionProCase:
            entity.addChild(model)
        case .ChristmasBlack:

            guard
                let scene = try? await Entity(
                    named: "ChristmasTreeScene",
                    in: realityKitContentBundle)
            else {
                print("Unable to load CaseWithCarScene")
                self.entity = entity
                return
            }
            entity.addChild(scene)

        }

        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        entity.isEnabled = anchor.isTracked

        self.entity = entity
    }

    func update(with anchor: ObjectAnchor) {
        entity.isEnabled = anchor.isTracked

        guard anchor.isTracked else { return }

        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)

    }
}
