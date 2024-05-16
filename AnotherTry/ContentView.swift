//
//  ContentView.swift
//  AnotherTry
//
//  Created by Nurbol on 30.11.2022.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase

class AppViewModel: ObservableObject {
    
    let auth = Auth.auth()
    let database = Database.database().reference()
    
    @Published var signedIn = false
    @Published var isAdmin = false
    
    var isSignedIn: Bool {
        return auth.currentUser != nil
    }
    
    func signIn(email: String, password: String) {
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let result = result, error == nil else {
                let message = error?.localizedDescription ?? "Unknown error"
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        rootViewController.present(alert, animated: true)
                    }
                }
                return
            }
            DispatchQueue.main.async {
                self?.isAdmin = result.user.email == "amangeldiyev.nurbol@gmail.com"
                
                //Success
                self?.signedIn = true
                
                // Save isAdmin to UserDefaults
                UserDefaults.standard.set(self?.isAdmin, forKey: "isAdmin")
            }
        }
    }


    
    func signUp(email: String, password: String) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let user = result?.user, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                self?.isAdmin = result?.user.email == "amangeldiyev.nurbol@gmail.com"
                //Success
                self?.signedIn = true
                
                // Save isAdmin to UserDefaults
                UserDefaults.standard.set(self?.isAdmin, forKey: "isAdmin")
                
                // Record user's UID and email in database
                let userData = ["uid": user.uid, "email": user.email ?? ""]
                let databaseRef = Database.database().reference().child("users").child(user.uid)
                databaseRef.setValue(userData) { error, _ in
                    if let error = error {
                        print("Error saving user data: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func signOut() {
        try? auth.signOut()
        
        self.signedIn = false
        self.isAdmin = false
        
        // Reset selected tab to the first one
        UserDefaults.standard.set(0, forKey: "selectedTab")
    }
}

struct ContentView: View {
    
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        NavigationView{
            if viewModel.signedIn {
                if UserDefaults.standard.bool(forKey: "isAdmin") {
                    AdminTabBar()
                } else {
                    
                    TabBarView()
                    
                    VStack {
                        Button(action: {
                            viewModel.signOut()
                        }, label: {
                            Text("Sign Out")
                                .padding()
                                .frame(width: 200, height: 50)
                                .background(Color.gray)
                                .foregroundColor(Color.black)
                        })
                    }
                }

            }
            else {
                SignInView()
            }
            
            
        }
        .onAppear {
            viewModel.signedIn = viewModel.isSignedIn
        }
    }
}

 
struct SignInView: View {
    @State var email = ""
    @State var password = ""
    @State var showingForgotPasswordAlert = false
    
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        VStack {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
            
            VStack {
                TextField("Email Address", text: $email)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                
                Button(action: {
                    guard !email.isEmpty, !password.isEmpty else {
                        return
                    }
                    
                    viewModel.signIn(email: email, password: password)
                }, label: {
                    Text("Sign in")
                        .foregroundColor(Color.black)
                        .frame(width: 200, height: 50)
                        .background(Color.gray)
                        .cornerRadius(20)
                        .padding()
                })
                
                NavigationLink("Create Account", destination: SignUpView())
                    .padding()
                
                Button(action: {
                    showingForgotPasswordAlert = true
                        }, label: {
                        Text("Forgot password?")
                            .foregroundColor(.blue)
                        })
                        .alert(isPresented: $showingForgotPasswordAlert) {
                    Alert(title: Text("Reset Password"), message: Text("Enter your email to reset your password"), primaryButton: .cancel(), secondaryButton: .default(Text("Reset"), action: {
                    Auth.auth().sendPasswordReset(withEmail: email) { error in
                            if let error = error {
                                print("Error sending password reset email: \(error.localizedDescription)")
                            } else {
                                print("Password reset email sent successfully")
                            }
                        }
                    }))
                }
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Sign in")
    }
}

struct SignUpView: View {
    @State var email = ""
    @State var password = ""
    
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        VStack {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
            
            VStack {
                TextField("Email Address", text: $email)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                
                SecureField("Password", text: $password)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                
                Button(action: {
                    guard !email.isEmpty, !password.isEmpty else {
                        return
                    }
                    
                    viewModel.signUp(email: email, password: password)
                }, label: {
                    Text("Create Account")
                        .foregroundColor(Color.black)
                        .frame(width: 200, height: 50)
                        .background(Color.gray)
                        .cornerRadius(20)
                        .padding()
                })
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Create Account")
    }
}

let user = Auth.auth().currentUser

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
