//
//  AppModel.swift
//  ChristmARsTree
//
//  Created by 福田陸弥 on 2024/12/13.
//


import ARKit
import RealityKit
import RealityKitContent
import UIKit

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    var allRequiredProvidersAreSupported: Bool {
        ObjectTrackingProvider.isSupported
    }

    var canEnterImmersiveSpace: Bool {
        worldSensingAuthorizationStatus == .allowed && ObjectTrackingProvider.isSupported
    }

    var immersiveSpaceState = ImmersiveSpaceState.closed {
        didSet {
            guard immersiveSpaceState == .closed else { return }

            arkitSession.stop()
        }
    }


    var anchorReferences: [UUID: ObjectAnchor] = [:]

    var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]
    var providersStoppedWithError = false

    private var arkitSession = ARKitSession()
    private var objectTrackingProvider: ObjectTrackingProvider?
    private var worldSensingAuthorizationStatus = ARKitSession.AuthorizationStatus.notDetermined

    let referenceObjectLoader = ReferenceObjectLoader()

    func queryWorldSensingAuthorization() async {
        let authorizationQuery = await arkitSession.queryAuthorization(for: [
            .worldSensing
        ])

        guard let authorizationResult = authorizationQuery[.worldSensing] else {
            fatalError(
                "Failed to obtain .worldSensing authorization query result")
        }

        worldSensingAuthorizationStatus = authorizationResult
    }

    func requestWorldSensingAuthorization() async {
        let authorizationRequest = await arkitSession.requestAuthorization(
            for: [.worldSensing])

        guard let authorizationResult = authorizationRequest[.worldSensing]
        else {
            fatalError(
                "Failed to obtain .worldSensing authorization request result")
        }

        worldSensingAuthorizationStatus = authorizationResult
    }

    func startTracking(with rootEntity: Entity) async {
        let referenceObjects = referenceObjectLoader.referenceObjects

        guard !referenceObjects.isEmpty else {
            fatalError("No reference objects found to start tracking")
        }

        let objectTrackingProvider = ObjectTrackingProvider(
            referenceObjects: referenceObjects)

        do {
            try await arkitSession.run([
                objectTrackingProvider,
            ])
        } catch {
            print("Error running arkitSession: \(error)")

            return
        }

        self.objectTrackingProvider = objectTrackingProvider

        Task {
            await processObjectUpdates(with: rootEntity)
        }
    }

    private func processObjectUpdates(with rootEntity: Entity) async {
        guard let objectTrackingProvider else {
            print(
                "Error obtaining handTrackingProvider upon processHandUpdates")

            return
        }

        for await anchorUpdate in objectTrackingProvider.anchorUpdates {
            let anchor = anchorUpdate.anchor
            let id = anchor.id

            switch anchorUpdate.event {
            case .added:

                anchorReferences[id] = anchor
                
                let model: Entity? =
                    referenceObjectLoader.usdzsPerReferenceObjectID[anchor.referenceObject.id]

                let visualization = await ObjectAnchorVisualization(
                    for: anchor,
                    withModel: model,
                    appModel: self)

                objectVisualizations[id] = visualization
                rootEntity.addChild(visualization.entity)

            case .updated:

                anchorReferences[id] = anchor
                objectVisualizations[id]?.update(with: anchor)

            case .removed:

                anchorReferences.removeValue(forKey: id)
                objectVisualizations[id]?.entity.removeFromParent()
                objectVisualizations.removeValue(forKey: id)

            }
        }
    }
}
