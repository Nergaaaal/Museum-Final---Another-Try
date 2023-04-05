//
//  HomeVC.swift
//  AnotherTry
//
//  Created by Nurbol on 03.12.2022.
//

import SwiftUI
import FirebaseAuth

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
                        Button(action: {
                        let email = "Amangeldiyev.nurbol@gmail.com"
                        guard let url = URL(string: "mailto:\(email)") else { return }
                        UIApplication.shared.open(url)
                        }) {
                            HStack{
                                Image(systemName: "pencil")
                                .padding(1)
                                Text("Стать автором")
                            }
                        }
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
        SaveVC()
    }
}
