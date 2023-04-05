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

struct Article: Identifiable {
    let id: String
    let title: String
    let text: String
    let imageURL: String
    let modelURL: String?
    var image: UIImage?
    var modelAnchor: AnchorEntity?
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
                    let article = Article(id: snapshot.key, title: title, text: text, imageURL: imageURL, modelURL: value["modelURL"] as? String, image: nil)
                    newArticles.append(article)
                }
            }
            newArticles.sort { $0.id > $1.id }
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
                .navigationBarTitle("Home")
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
    @AppStorage("fontSize") private var fontSize = 16.0
    let ref = Database.database().reference().child("article")
    let article: Article
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageUrlString = article.imageURL, let imageUrl = URL(string: imageUrlString) {
                    // использование библиотеки SDWebImageSwiftUI для загрузки и отображения изображений
                    ZStack(alignment: .bottomTrailing) {
                        WebImage(url: imageUrl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 230)
                            .clipped()
                            .cornerRadius(10)
                        
                        Button(action: {
                            self.isFavorite.toggle()
                            //addToFavorites()
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
                .disabled(!isModelLoaded)
                .sheet(isPresented: $isARViewPresented) {
                    ARViewContainer(article: article, isPresented: self.$isARViewPresented, isModelLoaded: self.$isModelLoaded)
                }
            }
                .padding()
        }
        .navigationBarTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
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
                    let article = Article(id: snapshot.key, title: title, text: text, imageURL: imageURL, modelURL: modelURL, image: nil)
                    newArticles.append(article)
                }
            }
            newArticles.sort { $0.id > $1.id }
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

struct ARViewContainer: UIViewRepresentable {
    
    typealias UIViewType = ARSCNView
    var article: Article
    var isPresented: Binding<Bool>
    var isModelLoaded: Binding<Bool>
    
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
        guard let modelURLString = article.modelURL else { // получаем ссылку на модель из объекта Article
            fatalError("Failed to get model URL.")
        }
        let ref = Storage.storage().reference(withPath: "article_models/\(modelURLString)")
        ref.downloadURL { url, error in
            if let error = error {
                fatalError("Failed to download model file: \(error.localizedDescription)")
            }
            
            // Загружаем модель по ссылке
            guard let modelURL = url else {
                fatalError("Failed to get model URL.")
            }
            guard let scene = try? SCNScene(url: modelURL, options: nil) else {
                fatalError("Failed to load scene from model URL.")
            }
            
            // Add the loaded scene to the AR view's scene
            let node = SCNNode()
            for child in scene.rootNode.childNodes {
                node.addChildNode(child)
            }
            arView.scene.rootNode.addChildNode(node)
        }
    }
}

/*
    private func addToFavorites() {
        guard let user = Auth.auth().currentUser else { return }
        let ref = Database.database().reference().child("users").child(user.uid).child("favorites")
        let articleRef = ref.child(article.id)
        let data = ["title": article.title, "text": article.text, "imageURL": article.imageURL , "modelURL": article.modelURL ?? "", "userId": user.uid]
        
        if isFavorite {
            articleRef.removeValue()
        } else {
            articleRef.setValue(data)
        }
    }
}
*/

struct Favorite {
    var id: String
    var title: String
    var text: String
    var image: UIImage?
    var modelURL: String?
    
    func toAnyObject() -> Any {
        return [
            "id": id,
            "title": title,
            "text": text,
            "image": image?.pngData()?.base64EncodedString(),
            "modelURL": modelURL
        ]
    }
}

struct HomeTestVC_Previews: PreviewProvider {
    static var previews: some View {
        ArticleListView()
    }
}
