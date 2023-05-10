//
//  AdminVC.swift
//  AnotherTry
//
//  Created by Nurbol on 03.12.2022.
//

import SwiftUI
import FirebaseStorage
import FirebaseDatabase
import SceneKit
import ARKit
import UIKit

var property = "AdminPanelView"

struct AdminVC: View {
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    NavigationLink(destination: ARViewContaine(), label: {
                        Image("View 3D model")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 450, height: 230)
                            .padding(5)
                    })
                }
            }
            .navigationTitle("Save")
        }
    }
}

struct ARViewContaine: UIViewRepresentable {
    
    typealias UIViewType = ARSCNView
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        let scene = SCNScene()
        arView.scene = scene
        loadModel(arView)
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
    }
    
    func loadModel(_ arView: ARSCNView) {
        // Получаем путь к файлу модели в проекте
        guard let modelURL = Bundle.main.url(forResource: "Cesar", withExtension: "usdz") else {
            fatalError("Failed to get model URL.")
        }
        guard let scene = try? SCNScene(url: modelURL, options: nil) else {
            fatalError("Failed to load scene.")
        }
        
        // Создаем SCNNode из загруженной модели
        let node = SCNNode()
        for childNode in scene.rootNode.childNodes {
            node.addChildNode(childNode)
        }
        
        // Устанавливаем позицию и масштаб модели
        node.position = SCNVector3(x: 0, y: 0, z: -1)
        node.scale = SCNVector3(x: 0.1, y: 0.1, z: 0.1)
        
        // Добавляем SCNNode в AR-сцену
        arView.scene.rootNode.addChildNode(node)
    }
}

/*
struct ARViewContaine: UIViewRepresentable {
    
    typealias UIViewType = ARSCNView
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        let scene = SCNScene()
        arView.scene = scene
        loadModel(arView)
        addGestureRecognizers(to: arView) // Добавляем жесты пользователей
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
    }
    
    func loadModel(_ arView: ARSCNView) {
        // Получаем путь к файлу модели в проекте
        guard let modelURL = Bundle.main.url(forResource: "Dombra", withExtension: "usdz") else {
            fatalError("Failed to get model URL.")
        }
        guard let scene = try? SCNScene(url: modelURL, options: nil) else {
            fatalError("Failed to load scene.")
        }
        
        // Создаем SCNNode из загруженной модели
        let node = SCNNode()
        for childNode in scene.rootNode.childNodes {
            node.addChildNode(childNode)
        }
        
        // Устанавливаем позицию и масштаб модели
        node.position = SCNVector3(x: 0, y: 0, z: -1)
        node.scale = SCNVector3(x: 0.1, y: 0.1, z: 0.1)
        
        // Добавляем SCNNode в AR-сцену
        arView.scene.rootNode.addChildNode(node)
    }
    
    func addGestureRecognizers(to arView: ARSCNView) {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        arView.addGestureRecognizer(pinchGestureRecognizer)
        
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        arView.addGestureRecognizer(rotationGestureRecognizer)
    }
    
    func didTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let arView = gestureRecognizer.view as? ARSCNView else {
            return
        }
        let touchLocation = gestureRecognizer.location(in: arView)
        let hitTestResults = arView.hitTest(touchLocation, options: nil)
        guard let hitTestResult = hitTestResults.first else {
            return
        }
        let node = hitTestResult.node
        node.runAction(SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 2))
    }
    
    func didPinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard let arView = gestureRecognizer.view as? ARSCNView else {
            return
        }
        let touchLocation = gestureRecognizer.location(in: arView)
        let pinchScaleX = Float(gestureRecognizer.scale) * node.scale.x
        let pinchScaleY = Float(gestureRecognizer.scale) * node.scale.y
        let pinchScaleZ = Float(gestureRecognizer.scale) * node.scale.z
        node.scale = SCNVector3(pinchScaleX, pinchScaleY, pinchScaleZ)
        gestureRecognizer.scale = 1
    }
    func didRotate(_ gestureRecognizer: UIRotationGestureRecognizer) {
        guard let arView = gestureRecognizer.view as? ARSCNView else {
            return
        }
        let touchLocation = gestureRecognizer.location(in: arView)
        let hitTestResults = arView.hitTest(touchLocation, options: nil)
        guard let hitTestResult = hitTestResults.first else {
            return
        }
        let node = hitTestResult.node
        let rotation = Float(gestureRecognizer.rotation)
        node.eulerAngles.y += rotation
        gestureRecognizer.rotation = 0
    }
}
*/

struct AdminVC_Previews: PreviewProvider {
    static var previews: some View {
        AdminVC()
    }
}
