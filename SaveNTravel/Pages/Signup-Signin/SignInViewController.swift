import SwiftUI
import FirebaseAuth

struct SignInViewController: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

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
                Alert(title: Text("Errore"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .padding()
    }

    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.alertMessage = error.localizedDescription
                self.showAlert = true
                return
            }
            // Gestione del login riuscito, ad esempio navigazione alla schermata successiva
        }
    }
}

struct SignInViewController_Previews: PreviewProvider {
    static var previews: some View {
        SignInViewController()
    }
}
