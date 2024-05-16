//
//  ArticleTest.swift
//  AnotherTry
//
//  Created by Nurbol on 30.03.2023.
//

import SwiftUI
import FirebaseStorage
import FirebaseDatabase
import UIKit
import UniformTypeIdentifiers

struct ArticleTest: View {
    @State var showImagePicker = false
    @State var showModelPicker = false
    @State private var isUploading = false
    @State private var showingAlert = false
    @State var articleTitle = ""
    @State var articleText = ""
    @State var articleImage: UIImage?
    @State var articleModel: URL?
    @State var articleID = UUID().uuidString
    @State var publishDate = Date()
    
    let storage = Storage.storage()
    let database = Database.database().reference()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Spacer()
                    Text("Enter article title:")
                    TextEditor(text: $articleTitle)
                        .frame(minHeight: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    
                    Text("Enter article text:")
                    TextEditor(text: $articleText)
                        .frame(minHeight: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    
                    if articleImage != nil {
                        Image(uiImage: articleImage!)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    
                    if articleModel != nil {
                        Text("Selected Model: \(articleModel!.lastPathComponent)")
                            .padding(.top, 10)
                    }
                    
                    VStack {
                        HStack{
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
                                self.showModelPicker = true
                            }) {
                                Text("Add 3D Model")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(10)
                            }
                            .sheet(isPresented: $showModelPicker) {
                                DocumentPicker(allowedContentTypes: [.usdz, UTType(filenameExtension: "obj")!, UTType(filenameExtension: "scn")!]) { url in
                                    self.articleModel = url
                                }
                            }
                        }
                        
                        Button(action: {
                            // Check if all required fields are filled
                                if articleTitle.isEmpty || articleText.isEmpty || articleImage == nil || articleModel == nil {
                                    return
                                }
                            
                            isUploading = true
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
                            let dateString = dateFormatter.string(from: publishDate)
                            let articleID = database.child("article").childByAutoId().key ?? ""
                            var articleData = [
                                "id": articleID,
                                "title": articleTitle,
                                "text": articleText,
                                "imageURL": "",
                                "modelURL": "",
                                "publishDate": dateString
                            ]

                            let dispatchGroup = DispatchGroup()

                            dispatchGroup.enter()
                            // Upload article image
                            if let imageData = articleImage?.jpegData(compressionQuality: 0.5) {
                                let imageRef = storage.reference().child("article_images").child("\(articleID).jpg")
                                let metadata = StorageMetadata()
                                metadata.contentType = "image/jpeg"
                                _ = imageRef.putData(imageData, metadata: metadata) { metadata, error in
                                    if let error = error {
                                        print("Error uploading article image: \(error.localizedDescription)")
                                        return
                                    }
                                    imageRef.downloadURL { url, error in
                                        if let error = error {
                                            print("Error getting article image download URL: \(error.localizedDescription)")
                                            return
                                        }
                                        if let url = url {
                                            articleData["imageURL"] = url.absoluteString
                                        }
                                        dispatchGroup.leave()
                                    }
                                }
                            } else {
                                dispatchGroup.leave()
                            }

                            dispatchGroup.enter()
                            // Upload article 3D model
                            if let modelURL = articleModel {
                                let modelRef: StorageReference
                                let contentType: String
                                if modelURL.pathExtension == "usdz" {
                                        modelRef = storage.reference().child("article_models").child("\(articleID).usdz")
                                        contentType = "model/vnd.usdz+zip"
                                    } else if modelURL.pathExtension == "obj" {
                                        modelRef = storage.reference().child("article_models").child("\(articleID).obj")
                                        contentType = "model/vnd.obj"
                                    } else if modelURL.pathExtension == "scn" {
                                            modelRef = storage.reference().child("article_models").child("\(articleID).scn")
                                            contentType = "model/vnd.scn"
                                    } else {
                                        dispatchGroup.leave()
                                        return
                                    }
                                let metadata = StorageMetadata()
                                metadata.contentType = contentType
                                _ = modelRef.putFile(from: modelURL, metadata: metadata) { metadata, error in
                                    if let error = error {
                                        print("Error uploading article model: \(error.localizedDescription)")
                                        return
                                    }
                                    modelRef.downloadURL { url, error in
                                        if let error = error {
                                            print("Error getting article model download URL: \(error.localizedDescription)")
                                            return
                                        }
                                        
                                        if let url = url {
                                            // Remove the port 443 from the URL string
                                            var urlString = url.absoluteString
                                            urlString = urlString.replacingOccurrences(of: ":443", with: "")
                                            articleData["modelURL"] = urlString
                                        }
                                    
                                        dispatchGroup.leave()
                                    }
                                }
                            } else {
                                dispatchGroup.leave()
                            }

                            // Wait for both uploads to complete
                            dispatchGroup.notify(queue: DispatchQueue.main) {
                                isUploading = false
                                database.child("article").childByAutoId().setValue(articleData)
                                articleTitle = ""
                                articleText = ""
                                articleImage = nil
                                articleModel = nil
                                showingAlert = true
                            }
                        }) {
                            Text("Submit Article")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
            .padding()
            .navigationBarTitle("New Article")
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Article Added"), message: Text("The article has been successfully added."), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $isUploading, content: {
                ZStack {
                    Color.white
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2)
                        .padding()
                }
            })
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var completionHandler: (UIImage?) -> Void

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completionHandler(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completionHandler(nil)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIDocumentPickerViewController
    typealias Coordinator = DocumentPickerCoordinator
    var allowedContentTypes: [UTType]
    var completionHandler: (URL) -> Void
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) {}
    
    func makeCoordinator() -> DocumentPicker.Coordinator {
        DocumentPickerCoordinator(completionHandler: completionHandler)
    }
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    var completionHandler: (URL) -> Void
    init(completionHandler: @escaping (URL) -> Void) {
        self.completionHandler = completionHandler
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            completionHandler(url)
        }
    }
}

struct ArticleTest_Previews: PreviewProvider {
    static var previews: some View {
        ArticleTest()
    }
}
