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

struct ARViewContainer: UIViewRepresentable {
    
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
        // Получаем ссылку на файл модели из Firebase Database
        let modelName = "Cesar.usdz"
        let ref = Storage.storage().reference(withPath: "Models/\(modelName)")
        ref.downloadURL { url, error in
            if let error = error {
                fatalError("Failed to download model file: \(error.localizedDescription)")
            }
            
            // Загружаем модель по ссылке
            guard let modelURL = url else {
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
}
*/
