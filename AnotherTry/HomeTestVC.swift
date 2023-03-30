//
//  HomeTestVC.swift
//  AnotherTry
//
//  Created by Nurbol on 30.03.2023.
//

import SwiftUI
import FirebaseStorage
import FirebaseDatabase
import SDWebImageSwiftUI

struct Article: Identifiable {
    let id: String
    let title: String
    let text: String
    let imageURL: String
    var image: UIImage?
}

class ArticleViewModel: ObservableObject {
    @Published var articles: [Article] = []
    
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
                    let article = Article(id: snapshot.key, title: title, text: text, imageURL: imageURL, image: nil)
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
    
    var body: some View {
        NavigationView {
            if viewModel.articles.isEmpty {
                VStack {
                    ProgressView()
                        .padding(10)
                    Text("Loading articles...")
                }
            } else {
                List {
                    ForEach(viewModel.articles) { article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            if let image = article.image {
                                Spacer().frame(width: 10)
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                                    .overlay(
                                        VStack {
                                            Spacer()
                                            Text(article.title)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 10)
                                                .padding(.bottom, 10)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                        }
                                    )
                            } else {
                                Rectangle()
                                    .foregroundColor(.gray)
                                    .frame(height: 200)
                            }
                        }
                        .frame(height: 200)
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 10)
                    }
                }
                .navigationBarTitle("Home")
            }
        }
    }
}

struct ArticleDetailView: View {
    let article: Article
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let image = article.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                } else {
                    Rectangle()
                        .foregroundColor(.gray)
                        .frame(height: 200)
                }
                
                Text(article.text)
                    .font(.body)
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitle(article.title)
    }
}

struct HomeTestVC_Previews: PreviewProvider {
    static var previews: some View {
        ArticleListView()
    }
}
