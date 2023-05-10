//
//  HomeTestVC.swift
//  AnotherTry
//
//  Created by Nurbol on 30.03.2023.
//

import SwiftUI
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth
import SDWebImageSwiftUI
import RealityKit
import ARKit

struct Article: Identifiable, Hashable {
    let id: String
    let publishDate: Date
    let title: String
    let text: String
    let imageURL: String
    let modelURL: String?
    var image: UIImage?
    var modelAnchor: AnchorEntity?
    var isFavorite: Bool = false
}

struct Favorite: Identifiable, Hashable {
    var id: String
    let publishDate: Date
    var title: String
    var text: String
    var imageURL: String
    var image: UIImage?
    var modelURL: String?
    
    init(id: String, title: String, text: String, imageURL: String, image: UIImage?, modelURL: String?) {
        self.id = id
        self.publishDate = Date()
        self.title = title
        self.text = text
        self.imageURL = imageURL
        self.image = image
        self.modelURL = modelURL
    }
    
    init?(snapshot: DataSnapshot) {
        guard let value = snapshot.value as? [String: Any],
              let title = value["title"] as? String,
              let text = value["text"] as? String,
              let imageURL = value["imageURL"] as? String,
              let id = value["id"] as? String else {
            return nil
        }
        
        self.id = id
        self.publishDate = Date()
        self.title = title
        self.text = text
        self.imageURL = imageURL
        self.image = nil
        self.modelURL = value["modelURL"] as? String
    }
    
    func toAnyObject() -> Any {
        return [
            "id": id,
            "title": title,
            "text": text,
            "imageURL": imageURL,
            "image": image?.pngData()?.base64EncodedString(),
            "modelURL": modelURL
        ]
    }
}

class ArticleViewModel: ObservableObject {
    @Published var articles: [Article] = []
    
    func filteredArticles(searchText: String) -> [Article] {
            if searchText.isEmpty {
                return articles
            } else {
                return articles.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
            }
        }
    
    init() {
        let ref = Database.database().reference().child("article")
        ref.observe(.value) { snapshot in
            var newArticles: [Article] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let value = snapshot.value as? [String: Any],
                   let title = value["title"] as? String,
                   let text = value["text"] as? String,
                   let imageURL = value["imageURL"] as? String {
                    let publishDate = Date() // задаем значение даты публикации
                    let article = Article(id: snapshot.key, publishDate: publishDate, title: title, text: text, imageURL: imageURL, modelURL: value["modelURL"] as? String, image: nil)

                    newArticles.append(article)
                }
            }
            newArticles.sort { $0.publishDate < $1.publishDate }
            self.articles = newArticles
            
            for i in 0..<self.articles.count {
                let article = self.articles[i]
                if let url = URL(string: article.imageURL) {
                    SDWebImageManager.shared.loadImage(with: url, options: .continueInBackground, progress: nil) { (image, _, _, _, _, _) in
                        if let image = image {
                            DispatchQueue.main.async {
                                self.articles[i].image = image
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ArticleListView: View {
    @ObservedObject var viewModel = ArticleViewModel()
    @State private var searchText = ""
    
    @Environment(\.font) var font

    var body: some View {
        NavigationView {
            if viewModel.articles.isEmpty {
                VStack {
                    ProgressView()
                        .padding(10)
                    Text("Loading articles...")
                }
            } else {
                List(viewModel.filteredArticles(searchText: searchText)) { article in
                    NavigationLink(destination: ArticleDetailView(article: article)) {
                        if let image = article.image {
                            Spacer().frame(width: 16)
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 360, height: 230)
                                .clipped()
                                .overlay(
                                    
                                    VStack {
                                        Spacer()
                                        Text(article.title)
                                            
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 10)
                                            .padding(.bottom, 10)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                            .font(.system(size: UIFont.preferredFont(forTextStyle: .body).pointSize * 1.5))
                                    }
                                    .background(Color.black.opacity(0.2))
                                )
                        } else {
                            Rectangle()
                                .foregroundColor(.gray)
                                .frame(height: 230)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .padding()
                }
                .listStyle(PlainListStyle())
                
                .searchable(text: $searchText) {
                }
            }
        }
    }
}

struct ArticleDetailView: View {
    
    @State var arView = ARView()
    @State var isFavorite = false
    @State var modelURL: String = ""
    @State private var isARViewPresented = false
    @State private var isModelLoaded = false
    @State private var isEditing = false
    @State private var isAdmin = false
    let ref = Database.database().reference().child("users")
    let article: Article
    
    @Environment(\.colorScheme) var colorScheme
    
    private var favoriteKey: String {
            "favorite-\(article.id)"
        }
        
        init(article: Article) {
            self.article = article
            _isFavorite = .init(initialValue: UserDefaults.standard.bool(forKey: favoriteKey))
        }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageUrl = URL(string: article.imageURL) {
                    ZStack(alignment: .bottomTrailing) {
                        WebImage(url: imageUrl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 230)
                            .clipped()
                            .cornerRadius(10)
                        
                        Button(action: {
                            self.isFavorite.toggle()
                            addToFavorites()
                            UserDefaults.standard.set(self.isFavorite, forKey: self.favoriteKey) // сохраняем состояние кнопки в UserDefaults
                        }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(isFavorite ? .red : .white)
                                .padding()
                        }
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                        .padding(10)
                    }
                } else {
                    Rectangle()
                        .foregroundColor(.gray)
                        .frame(height: 230)
                }
                
                Text(article.text)
                    .font(.body)
                
                Spacer()
                
                Button(action: {
                    print("Button tapped")
                    self.isARViewPresented = true
                }) {
                    Text("View 3D Model in AR")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .sheet(isPresented: $isARViewPresented) {
                    ARViewContainer(isModelLoaded: self.$isModelLoaded)
                }
            }
            .padding()
        }
        .navigationBarTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
                    self.isFavorite = UserDefaults.standard.bool(forKey: self.favoriteKey)
                }
    }
    
    func addToFavorites() {
        guard let user = Auth.auth().currentUser else { return }
        let favoriteRef = Database.database().reference().child("users/\(user.uid)/favorites/\(article.id)")
        let favorite = Favorite(id: article.id, title: article.title, text: article.text, imageURL: article.imageURL, image: nil, modelURL: modelURL)
        
        if isFavorite {
                // добавляем в избранное
            let favorite = Favorite(id: article.id, title: article.title, text: article.text, imageURL: article.imageURL, image: nil, modelURL: modelURL)
                favoriteRef.setValue(favorite.toAnyObject())
            } else {
                // удаляем из избранного
                favoriteRef.removeValue()
            }
    }
}

struct ARViewContainer: UIViewRepresentable {

    typealias UIViewType = ARSCNView
    @Binding var isModelLoaded: Bool
        
    let arView = ARSCNView()
    
    // Firebase Storage reference
    let storage = Storage.storage().reference()
    
    // Firebase Realtime Database reference
    let database = Database.database().reference()
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        let scene = SCNScene()
        arView.scene = scene
        arView.session.delegate = context.coordinator // Добавляем делегата AR сессии
        let configuration = ARWorldTrackingConfiguration() // Создаем конфигурацию AR сессии
        configuration.planeDetection = [.horizontal, .vertical] // Разрешаем обнаружение горизонтальных и вертикальных поверхностей
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors]) // Запускаем AR сессию
        
        // Добавляем распознавание жестов
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        loadModel(arView)
        print("loadModel called")
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
    }
    
    func loadModel(_ arView: ARSCNView) {
        // Загружаем URL модели из Firebase Realtime Database
        database.child("article_models").observeSingleEvent(of: .value, with: { snapshot in
            guard let modelURL = snapshot.value as? String else { return }
            print("Model URL: (modelURL)")
            // Загружаем модель из Firebase Storage
            self.storage.child(modelURL).downloadURL(completion: { url, error in
                guard let url = url, error == nil else { return }
                print("Model download URL: (url)")
                let scene = try? SCNScene(url: url, options: nil)
                guard let scene = scene else { return }
                print("Scene loaded")
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
                print("Node added to scene")
                // Устанавливаем isModelLoaded в true
                self.isModelLoaded = true
                print("loadModel finished")
            })
        })
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        
        let parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
            super.init()
            parent.arView.delegate = self
            parent.arView.session.delegate = self
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            parent.arView.session.run(configuration)
        }
        
        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            let tapLocation = gestureRecognizer.location(in: parent.arView)
            let hitTestResults = parent.arView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
            guard let hitTest = hitTestResults.first else { return }
            let anchor = ARAnchor(name: "modelURL", transform: hitTest.worldTransform)
            parent.arView.session.add(anchor: anchor)
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard anchor.name == "modelURL" else { return }
            let modelNode = parent.arView.scene.rootNode.clone()
            node.addChildNode(modelNode)
        }
    }
}

class ArticleModel: ObservableObject {
    @Published var articles: [Article] = []
    var arSession = ARSession()
    
    func filteredArticles(searchText: String) -> [Article] {
        if searchText.isEmpty {
            return articles
        } else {
            return articles.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    init() {
        let ref = Database.database().reference().child("article")
        ref.observe(.value) { snapshot in
            var newArticles: [Article] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let value = snapshot.value as? [String: Any],
                   let title = value["title"] as? String,
                   let text = value["text"] as? String,
                   let imageURL = value["imageURL"] as? String,
                   let modelURL = value["modelURL"] as? String { // добавляем модель в объект Article
                    let publishDate = Date() // или любое другое значение даты
                    let article = Article(id: snapshot.key, publishDate: publishDate, title: title, text: text, imageURL: imageURL, modelURL: modelURL, image: nil)
                    newArticles.append(article)
                }
            }
            newArticles.sort { $0.publishDate < $1.publishDate }
            self.articles = newArticles
            
            for i in 0..<self.articles.count {
                let article = self.articles[i]
                if let url = URL(string: article.imageURL) {
                    SDWebImageManager.shared.loadImage(with: url, options: .continueInBackground, progress: nil) { (image, _, _, _, _, _) in
                        if let image = image {
                            DispatchQueue.main.async {
                                self.articles[i].image = image
                            }
                        }
                    }
                }
            }
        }
    }
}

struct HomeTestVC_Previews: PreviewProvider {
    static var previews: some View {
        ArticleListView()
    }
}
