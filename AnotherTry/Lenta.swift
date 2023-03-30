//
//  Lenta.swift
//  AnotherTry
//
//  Created by Nurbol on 07.03.2023.
//

import SwiftUI
import FirebaseStorage
import FirebaseDatabase
import UIKit
/*
struct AdminVC: View {
    var body: some View {
        VStack {
            NavigationLink("Add new article", destination: Lenta())
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
*/

////////////////////////////////////////
/*
struct Lenta: View {
    let storageRef = Storage.storage().reference()
    @State private var image: Image? = nil
    
    var body: some View {
        VStack {
            Button(action: {
                self.downloadImage()
            }) {
                Text("Загрузить изображение из хранилища")
            }
            .padding()
            if image != nil {
                image!
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
        }
    }
    
    func downloadImage() {
        let imageRef = storageRef.child("article_images/Cesar.jpg")
        imageRef.downloadURL { (url, error) in
            guard let downloadURL = url else {
                return
            }
            self.loadImageFromURL(url: downloadURL)
        }
    }
    
    func loadImageFromURL(url: URL) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    self.image = Image(uiImage: UIImage(data: data)!)
                }
            }
        }
    }
}
*/

/*
struct Lenta: View {
    let storageRef = Storage.storage().reference()
    let databaseRef = Database.database().reference()
    
    @State private var textInput: String = ""
    @State private var image: Image? = nil
    
    var body: some View {
        VStack {
            TextField("Введите текст", text: $textInput)
                .padding()
            Button(action: {
                self.uploadToDatabase()
            }) {
                Text("Записать в базу данных")
            }
            .padding()
            Button(action: {
                self.uploadToStorage()
            }) {
                Text("Загрузить изображение в хранилище")
            }
            .padding()
            if image != nil {
                image!
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
        }
    }
    
    func uploadToDatabase() {
        let key = databaseRef.child("article").childByAutoId().key
        databaseRef.child("article").child(key!).setValue(textInput)
    }
    
    func uploadToStorage() {
        let imageRef = storageRef.child("article/image.jpg")
        guard let imageData = UIImage(named: "example-image")?.jpegData(compressionQuality: 0.8) else {
            return
        }
        imageRef.putData(imageData, metadata: nil) { (metadata, error) in
            guard metadata != nil else {
                return
            }
            imageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    return
                }
                self.loadImageFromURL(url: downloadURL)
            }
        }
    }
    
    func loadImageFromURL(url: URL) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    self.image = Image(uiImage: UIImage(data: data)!)
                }
            }
        }
    }
}
*/

/*
struct Lenta: View {
    // Ссылка на Firebase Storage
    let storage = Storage.storage().reference()
    // Ссылка на Firebase Database
    let database = Database.database().reference()
    // Данные для записи в Firebase Database
    let data = ["Name": "John", "Age": "30"]
    // Изображение для загрузки в Firebase Storage
    let image = UIImage(named: "myImage")
    
    var body: some View {
        VStack {
            Text("Hello, Firebase!")
            Button(action: {
                // Загружаем изображение в Firebase Storage
                guard let imageData = self.image?.jpegData(compressionQuality: 0.8) else { return }
                let imageRef = self.storage.child("myImage.jpg")
                imageRef.putData(imageData, metadata: nil) { (metadata, error) in
                    guard metadata != nil else { return }
                    print("Image uploaded successfully!")
                }
                
                // Записываем данные в Firebase Database
                self.database.child("users").childByAutoId().setValue(self.data) { (error, ref) in
                    if error != nil {
                        print("Error: \(error!.localizedDescription)")
                    } else {
                        print("Data saved successfully!")
                    }
                }
            }) {
                Text("Upload Data")
            }
        }
    }
}
*/

/*
struct Article {
    var title: String
    var text: String
    var imageName: String
    var model: String
}

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
                    let article = Article(title: title, text: text, imageName: imageName, model: model)
                    // сохраняем статью в хранилище или отправляем запрос на сервер
                    self.presentationMode.wrappedValue.dismiss()
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
}


struct Lenta_Previews: PreviewProvider {
    static var previews: some View {
        AddArticleView()
    }
}
*/
