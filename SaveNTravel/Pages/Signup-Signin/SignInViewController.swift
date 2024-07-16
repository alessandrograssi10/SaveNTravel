import SwiftUI

struct SignInViewController: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSignedIn = false // State per gestire il reindirizzamento
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Text("Happy to see you there again!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: true, vertical: true)
                }
                .padding(.bottom, 50)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: signIn) {
                    Text("Sign In")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding()
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
            .padding()
            .fullScreenCover(isPresented: $isSignedIn) {
                PageController() // Qui puoi navigare verso la pagina successiva dopo il login
            }
        }
    }
    
    private func signIn() {
        authViewModel.signIn(email: email, password: password) { success, error in
            if success {
                // Successful login, navigate to next screen
                self.isSignedIn = true
            } else {
                self.alertMessage = error ?? "Unknown error"
                self.showAlert = true
            }
        }
    }
}

struct SignInViewController_Previews: PreviewProvider {
    static var previews: some View {
        SignInViewController().environmentObject(AuthViewModel())
    }
}

