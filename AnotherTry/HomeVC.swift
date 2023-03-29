//
//  HomeVC.swift
//  AnotherTry
//
//  Created by Nurbol on 03.12.2022.
//

import SwiftUI
import FirebaseAuth

struct HomeVC: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    
                    NavigationLink(destination: CesarView(), label: {
                        Image("Cesar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 450, height: 230)
                            .padding(5)
                    })
                    
                    NavigationLink(destination: DiscobolView(), label: {
                        Image("Discobol")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 450, height: 230)
                            .padding(5)
                    })
                    
                    NavigationLink(destination: StatueOfLiberty(), label: {
                        Image("StatueOfLiberty")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 450, height: 230)
                            .padding(5)
                    })
                    
                    
                }
            }
            .navigationTitle("Home")
        }
    }
}

struct SaveVC: View {
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    NavigationLink(destination: CesarView(), label: {
                        Image("Cesar")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 450, height: 230)
                            .padding(5)
                    })
                    
                    NavigationLink(destination: StatueOfLiberty(), label: {
                        Image("StatueOfLiberty")
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

class SettingsViewModel: ObservableObject {
    
    var property = "SettingVC"
    
    let auth = Auth.auth()
    
    @Published var signedIn = false
    
    var isSignedIn: Bool {
        return auth.currentUser != nil
    }
    
    func signIn(email: String, password: String) {
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard result != nil, error == nil else {
                return
            }
            DispatchQueue.main.async {
                //Success
                self?.signedIn = true
            }
        }
    }
    
    func signUp(email: String, password: String) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard result != nil, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                //Success
                self?.signedIn = true
            }
        }
    }
    
    func signOut() {
        try? auth.signOut()
        
        self.signedIn = false
    }
}


struct SettingVC: View {
    
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        NavigationView{
            List{
                    
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
                        Image(systemName: "pencil")
                            .padding(1)
                        Link("Стать автором", destination: URL(string: "https://www.Google.com")!)
                        
                    }
                    
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
            .navigationTitle("Настройки")
            .foregroundColor(Color.primary)
            .background(Color.white)
        }
    }
}

struct InterfaceView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var fontSize: CGFloat = 16
    
    var body: some View {
        NavigationView {
            VStack {
                Picker ("Mode", selection: $isDarkMode) {
                    Text("Light")
                        .tag(false)
                    Text("Dark")
                        .tag(true)
                }.pickerStyle(SegmentedPickerStyle())
                    .padding()
                
                Stepper("Font size: \(Int(fontSize))", value: $fontSize, in: 10...30)
                                    .padding()
                
                Spacer()
            }
        }
        .navigationTitle("Mode switch")
        .foregroundColor(Color.primary)
        .font(.system(size: fontSize))
    }
}

struct TabBarView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        TabView {
            HomeVC()
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

struct HomeVC_Previews: PreviewProvider {
    static var previews: some View {
        HomeVC()
    }
}
