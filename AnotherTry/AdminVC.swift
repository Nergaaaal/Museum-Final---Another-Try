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

struct AdminVC_Previews: PreviewProvider {
    static var previews: some View {
        AdminVC()
    }
}
