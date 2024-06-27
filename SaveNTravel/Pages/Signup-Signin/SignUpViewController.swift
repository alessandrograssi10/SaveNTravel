import SwiftUI
import FirebaseAuth

struct SignUpViewController: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
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

            TextField("Nome Completo", text: $fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Numero di Telefono", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
                .padding()

            Button(action: signUp) {
                Text("Sign Up")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Errore"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .padding()
    }

    private func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.alertMessage = error.localizedDescription
                self.showAlert = true
                return
            }
            // Gestione della registrazione riuscita, ad esempio navigazione alla schermata successiva o completamento del profilo
        }
    }
}

struct SignUpViewController_Previews: PreviewProvider {
    static var previews: some View {
        SignUpViewController()
    }
}
