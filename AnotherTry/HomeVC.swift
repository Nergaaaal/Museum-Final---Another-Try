//
//  HomeVC.swift
//  AnotherTry
//
//  Created by Nurbol on 03.12.2022.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import SDWebImageSwiftUI
import RealityKit
import ARKit

class ArticleSaveViewModel: ObservableObject {
    @Published var articles: [Article] = []
    
    func filteredArticles(searchText: String) -> [Article] {
            if searchText.isEmpty {
                return articles
            } else {
                return articles.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
            }
        }
    
    init() {
        guard let uid = Auth.auth().currentUser?.uid else {
            // Обработка ошибки, если пользователь не авторизован
            return
        }
        let ref = Database.database().reference().child("users/\(uid)/favorites")
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

struct SaveVC: View {
    @ObservedObject var viewModel = ArticleSaveViewModel()
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
/*
struct SaveVC: View {
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    NavigationLink(destination: ArticleListView(), label: {
                        Image("Cesar")
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
 */

struct SettingVC: View {
    
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingPasswordReset = false
    
    var body: some View {
        NavigationView {
            List {
                Group {
                    if let user = Auth.auth().currentUser {
                        Text("Профиль")
                            .foregroundColor(Color.gray)
                            .font(.system(size: 21))
                            .padding(5)
                            .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: -20))
                        HStack{
                            Image(systemName: "person")
                            Text(user.email ?? "")
                                .padding(5)
                        }
                    }
                    Button(action: {
                        showingPasswordReset = true
                    }, label: {
                        HStack {
                            Image(systemName: "key")
                            Text("Сбросить пароль")
                        }
                    })
                }
                Group {
                    Text("Настройки приложения")
                        .foregroundColor(Color.gray)
                        .font(.system(size: 21))
                        .padding(5)
                        .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: -20))
                    
                    NavigationLink(destination: InterfaceView(), label: {
                        HStack{
                            Image(systemName: "gear")
                                .padding(5)
                            Text("Настроить интерфейс")
                                .padding(5)
                        }
                    })
                    .foregroundColor(Color.primary)
                }
                Group {
                    Text("Контакты и обратная связь")
                        .foregroundColor(Color.gray)
                        .font(.system(size: 21))
                        .padding(5)
                        .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: -20))
                    HStack{
                        Image(systemName: "star")
                            .padding(1)
                        Link("Поставить оценку", destination: URL(string: "https://www.Google.com")!)
                        
                    }
                    HStack{
                        Image(systemName: "message")
                            .padding(1)
                        Link("Написать в поддержку", destination: URL(string: "https://www.Google.com")!)
                            
                    }
                    
                    HStack{
                        Image(systemName: "map")
                            .padding(1)
                        Link("Посетить музей", destination: URL(string: "https://2gis.kz/almaty/firm/9429940001359005/76.930394%2C43.258497")!)
                            
                    }
                    
                    HStack{
                        Image(systemName: "info")
                            .padding(1)
                        Link("О нас", destination: URL(string: "https://qyzpu.edu.kz/")!)
                            
                    }
                }
                Group {
                    Button(action: {
                        viewModel.signOut()
                    }, label: {
                        HStack {
                            Image(systemName: "door.left.hand.open")
                            Text("Выйти")
                                .padding()

                        }
                    })
                }
            }
            .navigationTitle("Настройки")
            .foregroundColor(Color.primary)
            .background(Color.white)
            .sheet(isPresented: $showingPasswordReset, content: {PasswordResetView()
            })
        }
    }
}

struct PasswordResetView: View {
    @State var email = ""
    @State var showAlert = false
    @State var alertMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Введите адрес электронной почты, чтобы сбросить пароль")
                .font(.title)
            TextField("Адрес электронной почты", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button(action: {
                if self.email.isEmpty {
                    self.alertMessage = "Пожалуйста, введите адрес электронной почты"
                    self.showAlert = true
                } else {
                    Auth.auth().sendPasswordReset(withEmail: self.email) { error in
                        if error != nil {
                            self.alertMessage = "Не удалось отправить запрос на сброс пароля: (error.localizedDescription)"
                            self.showAlert = true
                        } else {
                            self.alertMessage = "Запрос на сброс пароля отправлен на ваш адрес электронной почты"
                            self.showAlert = true
                            self.email = ""
                        }
                    }
                }
            }, label: {
                Text("Отправить запрос")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
            })
        }
        .padding()
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text(alertMessage), dismissButton: .default(Text("OK")))
        })
    }
}

struct InterfaceView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("fontSize") private var fontSize = 16.0
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                    Toggle(isOn: $isDarkMode) {
                        Text("Dark Mode")

                    }
                }
                .padding()
                .padding(.top, 20)
                
                Stepper("Font size: \(Int(fontSize))", value: $fontSize, in: 10...25)
                                    .padding()
                
                Spacer()
            }
        }
        .navigationTitle("Mode switch")
        .foregroundColor(Color.primary)
        .environment(\.font, Font.system(size: fontSize)) // set font size for all views in the view hierarchy
        .onAppear {
            // Restore saved font size on app launch
            if let savedFontSize = UserDefaults.standard.value(forKey: "fontSize") as? Double {
                fontSize = savedFontSize
            }
        }
        .onChange(of: fontSize) { value in
            // Save font size when changed
            UserDefaults.standard.set(value, forKey: "fontSize")
        }
    }
}


struct TabBarView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        TabView {
            ArticleListView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .foregroundColor(Color.primary)
            
            SaveVC()
                .tabItem {
                    Image(systemName: "heart")
                    Text("Save")
                }
                .foregroundColor(Color.primary)
            
            SettingVC()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .foregroundColor(Color.primary)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

struct AdminTabBar: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        TabView {
            
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
            
            ArticleTest()
                .tabItem {
                    Image(systemName: "pencil")
                    Text("Article")
                }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

struct HomeVC_Previews: PreviewProvider {
    static var previews: some View {
        SettingVC()
    }
}
