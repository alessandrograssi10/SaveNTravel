import SwiftUI
import FirebaseAuth
import PhoneNumberKit

struct SignUpViewController: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let phoneNumberKit = PhoneNumberKit()

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("Really?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Haven't you ever traveled with us?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .fixedSize(horizontal: true, vertical: true)
            }
            .padding(.bottom, 50)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Name", text: $fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Surname", text: $fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            VStack(alignment: .leading, spacing: -100) {
                Text("Mobile")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top, -30)
                
                PhoneNumberTextFieldView(phoneNumber: $phoneNumber)
            }
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
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Errore"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func signUp() {
        // Verifica il numero di telefono
        do {
            let phoneNumber = try phoneNumberKit.parse(self.phoneNumber)
            // Formatta il numero di telefono
            let formattedPhoneNumber = phoneNumberKit.format(phoneNumber, toType: .e164)
            print("Formatted Phone Number: \(formattedPhoneNumber)")
            
            // Continua con la registrazione su Firebase
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    return
                }
                // Gestisci la registrazione avvenuta con successo
            }
        } catch {
            self.alertMessage = "Numero di telefono non valido"
            self.showAlert = true
        }
    }
}

struct PhoneNumberTextFieldView: UIViewRepresentable {
    @Binding var phoneNumber: String

    func makeUIView(context: Context) -> PhoneNumberTextField {
        let textField = PhoneNumberTextField()
        textField.withExamplePlaceholder = true
        textField.withDefaultPickerUI = true
        textField.withFlag = true // Abilita l'inferenza della bandiera
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)
        return textField
    }

    func updateUIView(_ uiView: PhoneNumberTextField, context: Context) {
        uiView.text = phoneNumber
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PhoneNumberTextFieldView

        init(_ parent: PhoneNumberTextFieldView) {
            self.parent = parent
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            if let phoneNumberTextField = textField as? PhoneNumberTextField {
                parent.phoneNumber = phoneNumberTextField.text ?? ""
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpViewController()
    }
}

