//
//  AddArticleVC.swift
//  AnotherTry
//
//  Created by Nurbol on 29.03.2023.
//

import SwiftUI
import FirebaseStorage
import FirebaseDatabase
import UIKit

struct AddArticleVC: View {
    @State var showImagePicker = false
    @State var articleTitle = ""
    @State var articleText = ""
    @State var articleImage: UIImage?
    let storage = Storage.storage()
    let database = Database.database().reference()

    var body: some View {
        VStack {
            TextField("Enter article title", text: $articleTitle)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            TextField("Enter article text", text: $articleText)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

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

                        let articleData = [
                            "title": articleTitle,
                            "text": articleText, // Add article text
                            "imageURL": url?.absoluteString ?? ""
                        ]
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


struct AddArticleVC_Previews: PreviewProvider {
    static var previews: some View {
        AddArticleVC()
    }
}
