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
import UIKit
import AVFoundation
import UniformTypeIdentifiers

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
    @Published var isAdmin: Bool = false
    
    func deleteArticle(at index: Int) {
        guard isAdmin else {
            print("User is not authorized to delete articles.")
            return
        }
        
        if articles.indices.contains(index) {
            DispatchQueue.main.async {
                self.articles.remove(at: index)
                self.updateImageIndices()
            }
            
            let article = articles[index]
            let ref = Database.database().reference().child("article").child(article.id)
            ref.removeValue { error, _ in
                if let error = error {
                    print("Failed to delete article: \(error.localizedDescription)")
                }
            }
        } else {
            print("Invalid index: \(index)")
        }
    }

    func updateImageIndices() {
        for i in 0..<articles.count {
            let article = articles[i]
            if let url = URL(string: article.imageURL) {
                SDWebImageManager.shared.loadImage(with: url, options: .continueInBackground, progress: nil) { (image, _, _, _, _, _) in
                    if let image = image {
                        DispatchQueue.main.async {
                            if let index = self.articles.firstIndex(where: { $0.id == article.id }) {
                                self.articles[index].image = image
                            }
                        }
                    }
                }
            }
        }
    }
    
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
            newArticles.sort { $0.publishDate > $1.publishDate }
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
    
    @State private var deleteArticle = false
    @State private var selectedArticle: Article? = nil
    
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if viewModel.isAdmin {
                            Button(action: {
                                guard viewModel.articles.firstIndex(where: { $0.id == article.id }) != nil else {
                                    return
                                }
                                selectedArticle = article
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    deleteArticle = true
                                }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .background(Color.red)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .searchable(text: $searchText) {
                }
            }
        }
        .actionSheet(isPresented: $deleteArticle) {
            ActionSheet(
                title: Text("Удалить статью?"),
                buttons: [
                    .destructive(Text("Да"), action: {
                        if let article = selectedArticle {
                            if let index = viewModel.articles.firstIndex(where: { $0.id == article.id }) {
                                viewModel.deleteArticle(at: index)
                            }
                        }
                    }),
                    .cancel(Text("Нет"), action: {
                        deleteArticle = false
                    })
                ]
            )
        }
        .onAppear {
                    viewModel.isAdmin = true
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
    @State private var isPlaying = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var speechProgress: Float = 0.0
    @State private var speechSpeed: Float = 0.5
    @State private var selectedSpeedIndex = 1
    
    @AppStorage("fontSize") private var fontSize = 16.0

    let ref = Database.database().reference().child("users")
    let article: Article
    
    private let speechSpeeds: [Float] = [1.0, 2.0]
    
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
                            UserDefaults.standard.set(self.isFavorite, forKey: self.favoriteKey)
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
                
                HStack {
                    Button(action: {
                        isPlaying.toggle()
                        if isPlaying {
                            startSpeechSynthesizer()
                        } else {
                            stopSpeechSynthesizer()
                        }
                    }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .gray)
                    
                    Slider(value: $speechProgress, in: 0.0...1.0)
                        .accentColor(.blue)
                        .disabled(isPlaying)
                        .onChange(of: speechProgress) { newValue in
                            if isPlaying {
                                let utterance = AVSpeechUtterance(string: article.text)
                                let spokenWordCount = Float(utterance.speechString.components(separatedBy: " ").count)
                                let spokenWords = Int(spokenWordCount * newValue)
                                utterance.postUtteranceDelay = 0.01
                                utterance.preUtteranceDelay = 0.01
                                utterance.rate = speechSpeed
                                speechSynthesizer.stopSpeaking(at: .word)
                                speechSynthesizer.speak(utterance)
                                for _ in 0..<spokenWords {
                                    speechSynthesizer.pauseSpeaking(at: .word)
                                }
                            }
                        }
                    
                    Picker(selection: $selectedSpeedIndex, label: Text("X2")) {
                        ForEach(Array(speechSpeeds.indices), id: \.self) { index in
                            Text(String(format: "%.1fx", speechSpeeds[index]))
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                .tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(colorScheme == .dark ? .white : .black)
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .onChange(of: selectedSpeedIndex) { newIndex in
                        if selectedSpeedIndex == 0 {
                            speechSpeed = 0.5
                        } else if selectedSpeedIndex == 2 {
                            speechSpeed = 1.5
                        } else {
                            speechSpeed = 1.0
                        }
                    }
                    .onChange(of: speechSpeed) { newSpeed in
                        if isPlaying {
                            stopSpeechSynthesizer()
                            startSpeechSynthesizer()
                        }
                    }
                }
                
                
                Text(article.text)
                    .font(.system(size: CGFloat(fontSize)))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
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
                .fullScreenCover(isPresented: $isARViewPresented) {
                    NavigationView {
                        //ARViewContainer(isModelLoaded: self.$isModelLoaded, articleID: self.article.id)
                        ARViewContainer(isModelLoaded: self.$isModelLoaded, articleTitle: self.article.title)
                            .navigationBarItems(trailing: Button("Close") {
                                self.isARViewPresented = false
                            })
                    }
                }
            }
            .padding()
        }
        .navigationBarTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            self.isFavorite = UserDefaults.standard.bool(forKey: self.favoriteKey)
        }
        .environment(\.font, Font.system(size: CGFloat(fontSize)))
    }
    
    func startSpeechSynthesizer() {
            let utterance = AVSpeechUtterance(string: article.text)
            utterance.rate = speechSpeed
            speechSynthesizer.speak(utterance)
        }
    
    func pauseSpeechSynthesizer() {
        speechSynthesizer.pauseSpeaking(at: .word)
    }
        
    func stopSpeechSynthesizer() {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    
    func addToFavorites() {
        guard let user = Auth.auth().currentUser else { return }
        let favoriteRef = Database.database().reference().child("users/\(user.uid)/favorites/\(article.id)")
        _ = Favorite(id: article.id, title: article.title, text: article.text, imageURL: article.imageURL, image: nil, modelURL: modelURL)
        
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
// Моделька не вызывается из папки
/*
struct ARViewContainer: UIViewControllerRepresentable {
    @Binding var isModelLoaded: Bool
    let articleTitle: String

    func makeUIViewController(context: Context) -> ARViewController {
        let arViewController = ARViewController()
        arViewController.delegate = context.coordinator
        return arViewController
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
        // Update the AR view controller with any necessary changes
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, ARViewControllerDelegate, ARSCNViewDelegate {
        let parent: ARViewContainer

        init(_ parent: ARViewContainer) {
            self.parent = parent
        }

        func arViewController(_ arViewController: ARViewController, didLoadScene scene: SCNScene) {
                // Load the 3D model based on the article title
                loadModel(for: parent.articleTitle) { modelURL in
                    if let modelURL = modelURL {
                        print("Model loaded successfully for model URL:", modelURL)
                        // Create a node and add it to the scene
                        let modelNode = SCNReferenceNode(url: modelURL)!
                        modelNode.name = "modelNode"
                        scene.rootNode.addChildNode(modelNode)
                        print("Model added to the scene")
                        self.parent.isModelLoaded = true
                        print("isModelLoaded set to true")

                        // Run ARKit configuration to find a horizontal plane
                        let configuration = ARWorldTrackingConfiguration()
                        configuration.planeDetection = .horizontal
                        arViewController.arView.session.run(configuration)
                        print("Running ARKit configuration to find a horizontal plane")

                        // Set the ARSCNView delegate to monitor plane detection and model manipulation
                        arViewController.arView.delegate = self
                        arViewController.arView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(_:))))
                        arViewController.arView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture(_:))))
                        arViewController.arView.addGestureRecognizer(UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotationGesture(_:))))
                    } else {
                        print("Failed to load model for article title:", self.parent.articleTitle)
                        // Handle error if model loading fails
                    }
                }
            }

        @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
            guard let arView = gesture.view as? ARSCNView else { return }
            let touchLocation = gesture.location(in: arView)
            let hitTestResults = arView.hitTest(touchLocation, options: nil)
            guard let hitTestResult = hitTestResults.first else { return }
            let modelNode = hitTestResult.node

            switch gesture.state {
            case .began:
                // Save the initial position of the model node
                modelNode.removeAllActions()
            case .changed:
                // Move the model node based on the pan gesture
                let translation = gesture.translation(in: arView)
                let deltaX = Float(translation.x) / Float(arView.bounds.width)
                let deltaY = Float(translation.y) / Float(arView.bounds.height)
                modelNode.localTranslate(by: SCNVector3(deltaX, -deltaY, 0.0))
                gesture.setTranslation(.zero, in: arView)
            default:
                break
            }
        }

        @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
            guard let arView = gesture.view as? ARSCNView else { return }
            let touchLocation = gesture.location(in: arView)
            let hitTestResults = arView.hitTest(touchLocation, options: nil)
            guard let hitTestResult = hitTestResults.first else { return }
            let modelNode = hitTestResult.node

            switch gesture.state {
            case .began:
                // Save the initial scale of the model node
                modelNode.removeAllActions()
            case .changed:
                // Scale the model node based on the pinch gesture
                let scale = Float(gesture.scale)
                modelNode.scale = SCNVector3(scale, scale, scale)
                gesture.scale = 1.0
            default:
                break
            }
        }

        @objc func handleRotationGesture(_ gesture: UIRotationGestureRecognizer) {
            guard let arView = gesture.view as? ARSCNView else { return }
            let touchLocation = gesture.location(in: arView)
            let hitTestResults = arView.hitTest(touchLocation, options: nil)
            guard let hitTestResult = hitTestResults.first else { return }
            let modelNode = hitTestResult.node

            switch gesture.state {
            case .began:
                // Save the initial rotation of the model node
                modelNode.removeAllActions()
            case .changed:
                // Rotate the model node based on the rotation gesture
                let rotation = Float(gesture.rotation)
                modelNode.localRotate(by: SCNQuaternion(0, rotation, 0, 1))
                gesture.rotation = 0.0
            default:
                break
            }
        }

        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            // Check if the added anchor is of type ARPlaneAnchor
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

            // Create an anchor node with a plane visualization
            let anchorNode = createPlaneNode(anchor: planeAnchor)
            node.addChildNode(anchorNode)
            print("Plane node added to the scene")

            // Add the model node as a child of the anchor node
            if let modelNode = node.childNode(withName: "modelNode", recursively: true) {
                anchorNode.addChildNode(modelNode)
                print("Model node added as a child of the anchor node")
            }
        }

        func createPlaneNode(anchor: ARPlaneAnchor) -> SCNNode {
            // Create a plane geometry with the size of the detected plane
            let planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))

            // Create a plane node with the geometry
            let planeNode = SCNNode(geometry: planeGeometry)

            // Position the plane node based on the anchor
            planeNode.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
            planeNode.eulerAngles.x = -.pi / 2  // Rotate the plane to be horizontal

            // Add a semi-transparent material to the plane
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
            planeGeometry.materials = [material]

            return planeNode
        }

        func loadModel(for articleTitle: String, completion: @escaping (URL?) -> Void) {
            print("Loading model for article title:", articleTitle)
            
            guard let modelURL = Bundle.main.url(forResource: articleTitle, withExtension: "usdz") ?? Bundle.main.url(forResource: articleTitle, withExtension: "obj") ?? Bundle.main.url(forResource: articleTitle, withExtension: "scn") else {
                print("Failed to retrieve model URL for article title:", articleTitle)
                completion(nil)
                return
            }
            
            print("Model URL obtained for article title:", articleTitle)
            completion(modelURL)
        }
    }
}

protocol ARViewControllerDelegate: AnyObject {
    func arViewController(_ arViewController: ARViewController, didLoadScene scene: SCNScene)
}

class ARViewController: UIViewController {
    weak var delegate: ARViewControllerDelegate?

    lazy var arView: ARSCNView = {
        let arView = ARSCNView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return arView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(arView)
        arView.delegate = self
        delegate?.arViewController(self, didLoadScene: arView.scene)
        setupARSession()
    }

    func setupARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)
    }
}

extension ARViewController: ARSCNViewDelegate {
    // Implement any necessary ARSCNViewDelegate methods
}
*/
/*
// Этот код последний рабочий
struct ARViewContainer: UIViewRepresentable {
    
    typealias UIViewType = ARSCNView
    @Binding var isModelLoaded: Bool
    
    let arView = ARSCNView()
    let articleID: String
    
    // Firebase Storage reference
    let storage = Storage.storage().reference()
    
    // Firebase Realtime Database reference
    let database = Database.database().reference().child("article")
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        let scene = SCNScene()
        arView.scene = scene
        arView.session.delegate = context.coordinator // Add AR session delegate
        let configuration = ARWorldTrackingConfiguration() // Create AR session configuration
        configuration.planeDetection = [.horizontal, .vertical] // Allow detection of horizontal and vertical planes
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors]) // Run AR session
        
        // Add gesture recognition
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        loadModel(arView) {
            print("Model loaded")
            // Perform additional commands or actions after the model is loaded
        }
        
        print("loadModel called")
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Check if model is already loaded
        guard !self.isModelLoaded else { return }
        // Check if AR session is ready
        guard let configuration = uiView.session.configuration else { return }
        // If ready, run AR session and load model
        uiView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        loadModel(uiView) {
            print("Model loaded")
            // Perform additional commands or actions after the model is loaded
        }
    }
    
    func loadModel(_ arView: ARSCNView, completion: @escaping () -> Void) {
        // Load model URL from Firebase Realtime Database for current article
        database.child(articleID).observeSingleEvent(of: .value, with: { snapshot in
            guard let modelURL = snapshot.childSnapshot(forPath: "modelURL").value as? String else {
                print("Error loading model URL")
                return
            }
            print("Model URL: \(modelURL)")
            // Load model from Firebase Storage
            self.storage.child("article_models/\(modelURL)").downloadURL(completion: { url, error in
                guard let url = url, error == nil else {
                    print("Error loading model download URL")
                    return
                }
                print("Model download URL: \(url)")
                let scene = try? SCNScene(url: url, options: nil)
                guard let scene = scene else {
                    print("Error loading scene")
                    return
                }
                print("Scene loaded")
                // Create SCNNode from loaded model
                let node = SCNNode()
                for childNode in scene.rootNode.childNodes {
                    node.addChildNode(childNode)
                }
                // Set position and scale of model
                node.position = SCNVector3(x: 0, y: -2, z: -3.0)
                node.scale = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
                // Add SCNNode to AR scene
                arView.scene.rootNode.addChildNode(node)
                print("Node added to scene")
                // Set isModelLoaded to true
                self.isModelLoaded = true
                print("loadModel finished")
                completion() // Call the completion handler after the model is loaded
            })
        })
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        
        let parent: ARViewContainer
        
        var lastPanLocation: CGPoint?
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
            super.init()
            parent.arView.delegate = self
            parent.arView.session.delegate = self
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            parent.arView.session.run(configuration)
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            parent.arView.addGestureRecognizer(pinchGesture)
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            parent.arView.addGestureRecognizer(panGesture)
        }
        
        @objc func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
            guard let sceneView = gestureRecognizer.view as? ARSCNView else { return }
            let location = gestureRecognizer.location(in: sceneView)
            let hitTestResults = sceneView.hitTest(location, options: nil)
            guard let hitTest = hitTestResults.first, let parentNode = hitTest.node.parent else { return }
            let scale = gestureRecognizer.scale
            parentNode.scale = SCNVector3(scale, scale, scale)
            gestureRecognizer.scale = 1
        }
        
        // Обработчик жестов пальцев
        @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
            switch gestureRecognizer.state {
            case .began:
                // Сохраняем начальную позицию курсора
                lastPanLocation = gestureRecognizer.location(in: parent.arView)
            case .changed:
                // Вычисляем величину движения курсора
                guard let lastPanLocation = lastPanLocation else { return }
                let translation = gestureRecognizer.translation(in: parent.arView)
                let deltaX = Float(translation.x - lastPanLocation.x) / Float(parent.arView.bounds.width)
                let deltaY = Float(translation.y - lastPanLocation.y) / Float(parent.arView.bounds.height)
                // Создаем вектор для поворота модели
                let rotation = simd_quatf(angle: sqrt(deltaX * deltaX + deltaY * deltaY) * Float.pi, axis: simd_float3(deltaY, deltaX, 0))
                // Изменяем поворот модели
                parent.arView.scene.rootNode.childNodes.forEach { $0.simdLocalRotate(by: rotation) }
                // Сохраняем текущую позицию курсора
                self.lastPanLocation = gestureRecognizer.location(in: parent.arView)
            case .ended:
                // Сбрасываем последнюю позицию курсора
                lastPanLocation = nil
            default:
                break
            }
        }
        
        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            let tapLocation = gestureRecognizer.location(in: parent.arView)
            guard let query = parent.arView.raycastQuery(from: tapLocation, allowing: .existingPlaneGeometry, alignment: .any) else {
                return
            }
            let hitTestResults = parent.arView.session.raycast(query)
            guard let hitTest = hitTestResults.first else {
                print("No hit test results found")
                return
            }
            
            // Создаем якорь на позиции обнаруженной плоскости
            let anchor = ARAnchor(name: "modelURL", transform: hitTest.worldTransform)
            parent.arView.session.add(anchor: anchor)
            print("AR anchor added")
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            guard anchor.name == "modelURL" else { return }
            let modelNode = parent.arView.scene.rootNode.clone()
            node.addChildNode(modelNode)
            
            // Устанавливаем позицию модели в мировых координатах, чтобы она соответствовала якорю
            modelNode.position = SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
            
            // Устанавливаем поворот модели, чтобы она всегда смотрела в ту же сторону
            modelNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: Float.pi)
            
            print("Model node added")
        }
    }
}
*/

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
            newArticles.sort { $0.publishDate > $1.publishDate }
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
/*
//Вызов 3Д модели из папки - работает
struct ARViewContainer: UIViewRepresentable {
    
    typealias UIViewType = ARSCNView
    @Binding var isModelLoaded: Bool
    
    let arView = ARSCNView()
    
    // Firebase Storage reference
    let storage = Storage.storage().reference()
    
    // Firebase Realtime Database reference
    let database = Database.database().reference()
    
    let articleTitle: String
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        let scene = SCNScene()
        arView.scene = scene
        arView.session.delegate = context.coordinator // Добавляем делегата AR сессии
        
        // Создаем конфигурацию AR сессии
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical] // Разрешаем обнаружение горизонтальных и вертикальных поверхностей
        configuration.environmentTexturing = .automatic // Включаем автоматическую обработку текстур
        configuration.isAutoFocusEnabled = true // Включаем автоматическую фокусировку камеры
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors]) // Запускаем AR сессию
        
        loadModel(arView, articleTitle: articleTitle)
        print("loadModel called")
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
    }
    
    func loadModel(_ arView: ARSCNView, articleTitle: String) {
        // Создаем путь к модели
        guard let modelURL = Bundle.main.url(forResource: articleTitle, withExtension: "usdz") ?? Bundle.main.url(forResource: articleTitle, withExtension: "obj") else {
            print("Cannot get model URL")
            return
        }
        print("Model URL: \(modelURL)")
        let scene = try? SCNScene(url: modelURL, options: nil)
        guard let scene = scene else {
            print("Cannot load scene from URL")
            return
        }
        print("Scene loaded: \(articleTitle)")
        // Создаем SCNNode из загруженной модели
        let node = SCNNode()
        for childNode in scene.rootNode.childNodes {
            node.addChildNode(childNode)
        }
        // Устанавливаем позицию и масштаб модели
        node.position = SCNVector3(x: 0, y: -2, z: -4.0)
        node.scale = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        // Добавляем SCNNode в AR-сцену
        arView.scene.rootNode.addChildNode(node)
        print("Node added to scene: \(articleTitle)")
        // Устанавливаем isModelLoaded в true
        self.isModelLoaded = true
        print("loadModel finished: \(articleTitle)")
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
            
            // Создаем конфигурацию AR сессии
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical] // Разрешаем обнаружение горизонтальных и вертикальных поверхностей
            configuration.environmentTexturing = .automatic // Включаем автоматическую обработку текстур
            configuration.isAutoFocusEnabled = true // Включаем автоматическую фокусировку камеры
            
            parent.arView.session.run(configuration) // Запускаем AR сессию
        }
        
        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            // Если добавляемый якорь - горизонтальная плоскость, то размещаем на ней 3D-модель
            if let planeAnchor = anchor as? ARPlaneAnchor {
                let modelNode = parent.arView.scene.rootNode.clone()
                node.addChildNode(modelNode)
                modelNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            }
        }
    }
}
 */

struct ARViewContainer: UIViewRepresentable {
    
    typealias UIViewType = ARSCNView
    @Binding var isModelLoaded: Bool
    
    let arView = ARSCNView()
    
    // Firebase Storage reference
    let storage = Storage.storage().reference()
    
    // Firebase Realtime Database reference
    let database = Database.database().reference()
    
    let articleTitle: String
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        let scene = SCNScene()
        arView.scene = scene
        arView.session.delegate = context.coordinator // Добавляем делегата AR сессии
        
        // Создаем конфигурацию AR сессии
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical] // Разрешаем обнаружение горизонтальных и вертикальных поверхностей
        configuration.environmentTexturing = .automatic // Включаем автоматическую обработку текстур
        configuration.isAutoFocusEnabled = true // Включаем автоматическую фокусировку камеры
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors]) // Запускаем AR сессию
        
        loadModel(arView, articleTitle: articleTitle)
        print("loadModel called")
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
    }
    
    func loadModel(_ arView: ARSCNView, articleTitle: String) {
        // Создаем путь к модели
        guard let modelURL = Bundle.main.url(forResource: articleTitle, withExtension: "usdz") ?? Bundle.main.url(forResource: articleTitle, withExtension: "obj") else {
            print("Cannot get model URL")
            return
        }
        
        print("Model URL: \(modelURL)")
        let scene = try? SCNScene(url: modelURL, options: nil)
        
        guard let scene = scene else {
            print("Cannot load scene from URL")
            return
        }
        print("Scene loaded: \(articleTitle)")
        // Создаем SCNNode из загруженной модели
        let node = SCNNode()
        for childNode in scene.rootNode.childNodes {
            node.addChildNode(childNode)
        }
        // Устанавливаем позицию и масштаб модели
        node.position = SCNVector3(x: 0, y: -4, z: -4.0)
        node.scale = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        // Добавляем SCNNode в AR-сцену
        arView.scene.rootNode.addChildNode(node)
        print("Node added to scene: \(articleTitle)")
        // Устанавливаем isModelLoaded в true
        self.isModelLoaded = true
        print("loadModel finished: \(articleTitle)")
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate, UIGestureRecognizerDelegate {
        
        let parent: ARViewContainer
        var selectedNode: SCNNode?
        var initialScale: SCNVector3 = SCNVector3(1, 1, 1)
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
            super.init()
            parent.arView.delegate = self
            parent.arView.session.delegate = self
            
            // Создаем конфигурацию AR сессии
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical] // Разрешаем обнаружение горизонтальных и вертикальных поверхностей
            configuration.environmentTexturing = .automatic // Включаем автоматическую обработку текстур
            configuration.isAutoFocusEnabled = true // Включаем автоматическую фокусировку камеры
            
            parent.arView.session.run(configuration) // Запускаем AR сессию
        }
        
        private func addGestureRecognizers(to arView: ARSCNView) {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            panGesture.delegate = self
            arView.addGestureRecognizer(panGesture)
            
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            pinchGesture.delegate = self
            arView.addGestureRecognizer(pinchGesture)
            
            let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
            rotationGesture.delegate = self
            arView.addGestureRecognizer(rotationGesture)
        }
        
        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let node = selectedNode else {
                return
            }
            
            let translation = gesture.translation(in: gesture.view)
            let currentPosition = node.position
            
            let newPosition = SCNVector3(
                currentPosition.x + Float(translation.x / 100),
                currentPosition.y,
                currentPosition.z - Float(translation.y / 100)
            )
            
            node.position = newPosition
            
            gesture.setTranslation(.zero, in: gesture.view)
        }
        
        @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let node = selectedNode else {
                return
            }
            
            if gesture.state == .began {
                initialScale = node.scale
            }
            
            let scale = Float(gesture.scale)
            let scaledValue = SCNVector3(initialScale.x * scale, initialScale.y * scale, initialScale.z * scale)
            
            node.scale = scaledValue
            
            gesture.scale = 1.0
        }
        
        @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let node = selectedNode else {
                return
            }
            
            let rotation = Float(gesture.rotation)
            node.eulerAngles.y -= rotation
            
            gesture.rotation = 0.0
        }
    }
}

struct HomeTestVC_Previews: PreviewProvider {
    static var previews: some View {
        ArticleListView()
    }
}
