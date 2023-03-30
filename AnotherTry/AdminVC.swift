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

/*
struct AdminVC: View {
    var body: some View {
        VStack {
            NavigationLink("Add new article", destination: AddArticleVC())
                .foregroundColor(Color.black)
                .frame(width: 200, height: 50)
                .cornerRadius(8)
                .background(Color.gray)
                .padding()
            
            NavigationLink("AR режим", destination: ARViewContainer())
                .foregroundColor(Color.black)
                .frame(width: 200, height: 50)
                .cornerRadius(8)
                .background(Color.gray)
                .padding()
            
                    Text("Admin Panel")
                    
                    Spacer()
                }
    }
}

struct Lenta: View {
    @State var showImagePicker = false
    @State var articleTitle = ""
    @State var articleText = ""
    @State var articleImage: UIImage?
    let storage = Storage.storage()
    let database = Database.database().reference()
    let onArticleAdded: ([String: Any]) -> Void // closure to be called when an article is added

    var body: some View {
        VStack {
            Text("Добавьте заголовок:")
            TextField("Enter article title", text: $articleTitle)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)

            Text("Добавьте текст:")
            TextField("Enter article text", text: $articleText)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)

            if articleImage != nil {
                Image(uiImage: articleImage!)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }

            Button(action: {
                self.showImagePicker = true
            }) {
                Text("Add Article Image")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: .photoLibrary) { image in
                    self.articleImage = image
                }
            }

            Button(action: {
                guard let imageData = articleImage?.jpegData(compressionQuality: 0.5) else { return }
                let articleID = database.child("article").childByAutoId().key ?? ""
                let imageRef = storage.reference().child("article_images/\(articleID).jpg")
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                imageRef.putData(imageData, metadata: metadata) { metadata, error in
                    if let error = error {
                        print("Error uploading article image: \(error.localizedDescription)")
                        return
                    }

                    imageRef.downloadURL { url, error in
                        if let error = error {
                            print("Error getting article image download URL: \(error.localizedDescription)")
                            return
                        }

                        let articleData = [                            "title": articleTitle,                            "text": articleText,                            "imageURL": url?.absoluteString ?? ""                        ]
                        database.child("article").child(articleID).setValue(articleData)
                    }
                }
            }) {
                Text("Add New Article")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var completionHandler: (UIImage?) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completionHandler: completionHandler)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No update needed
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var completionHandler: (UIImage?) -> Void
        
        init(completionHandler: @escaping (UIImage?) -> Void) {
            self.completionHandler = completionHandler
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                completionHandler(image)
            } else {
                completionHandler(nil)
            }
            picker.dismiss(animated: true, completion: nil)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completionHandler(nil)
            picker.dismiss(animated: true, completion: nil)
        }
    }
}
*/
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


/*
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
        // Имя файла модели
        let modelName = "Dombra"
        
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "usdz") ?? Bundle.main.url(forResource: modelName, withExtension: "obj") ??
            Bundle.main.url(forResource: modelName, withExtension: "scn") ??
            Bundle.main.url(forResource: modelName, withExtension: "dae") ??
            Bundle.main.url(forResource: modelName, withExtension: "abc") else {
            fatalError("Failed to find model file.")
        }
        
        guard let scene = try? SCNScene(url: modelURL, options: nil) else {
            fatalError("Failed to load scene.")
        }
        
        let node = SCNNode()
        for childNode in scene.rootNode.childNodes {
            node.addChildNode(childNode)
        }
        
        // Устанавливаем позицию и масштаб модели
        node.position = SCNVector3(x: 0, y: 0, z: -1)
        node.scale = SCNVector3(x: 0.1, y: 0.1, z: 0.1)
        
        arView.scene.rootNode.addChildNode(node)
    }
}
 */

struct AdminTabBar: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        TabView {
            AddArticleVC()
                .tabItem {
                    Image(systemName: "pencil")
                    Text("Article")
                }
            
            ArticleListView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            SaveVC()
                .tabItem {
                    Image(systemName: "heart")
                    Text("Save")
                }
            
            SettingVC()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

/*
struct Article {
    var title: String
    var text: String
    var imageName: String
    var model: String
}

let db = Database.database()
let storage = Storage.storage()

struct AddArticleView: View {
    @State private var title = ""
    @State private var text = ""
    @State private var imageName = ""
    @State private var model = ""
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Title", text: $title)
                    .padding()
                TextField("Text", text: $text)
                    .padding()
                TextField("Image Name", text: $imageName)
                    .padding()
                TextField("Model", text: $model)
                    .padding()
                
                Spacer()
                
                Button("Add Article") {
                    // Сохраняем данные в Firestore
                    let articleData: [String: Any] = [
                        "title": title,
                        "text": text,
                        "imageName": imageName,
                        "model": model
                    ]
                    
                    let ref = Database.database().reference()
                    let articlesRef = ref.child("articles")
                    articlesRef.childByAutoId().setValue(articleData) { error, ref in
                        if let error = error {
                            print("Error adding article: \(error.localizedDescription)")
                        } else {
                            print("Article added successfully")
                        }
                    }

                        
                        // Загружаем фото в Storage
                        let storage = Storage.storage()
                        let storageRef = storage.reference().child("article_images/\(imageName)")
                        
                        if let image = UIImage(named: imageName),
                           let imageData = image.jpegData(compressionQuality: 1.0) {
                           // Upload image data to Firebase Storage
                           let storage = Storage.storage()
                           let storageRef = storage.reference().child("article_images/\(imageName)")
                           storageRef.putData(imageData, metadata: nil) { metadata, error in
                              if let error = error {
                                 // Handle errors during image upload
                                 print("Error uploading image: \(error.localizedDescription)")
                                 return
                              }
                              // Image upload successful, continue saving article data to Firestore
                              // ...
                           }
                        } else {
                           // Handle errors if image is nil or there's an issue with creating JPEG data
                           print("Error creating image or JPEG data")
                        }
                    }
                }
                .padding()
                .disabled(title.isEmpty || text.isEmpty || imageName.isEmpty || model.isEmpty)
            }
            .navigationTitle("Add Article")
            .navigationBarItems(trailing: Button("Cancel") {
                self.presentationMode.wrappedValue.dismiss()
            })
        }
    }

struct AdminVC_Previews: PreviewProvider {
    static var previews: some View {
        AdminVC()
    }
}
 */
