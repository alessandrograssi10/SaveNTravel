import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhoneNumberKit

struct SignUpViewController: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var Name: String = ""
    @State private var Surname: String = ""
    @State private var phoneNumber: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSignedUp = false
    
    private var db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
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
                    .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Name", text: $Name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Surname", text: $Surname)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Mobile")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                    
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
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Errore"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                
                .fullScreenCover(isPresented: $isSignedUp) {
                                PageController()
                            }
            }
            .padding()
        }
    }
    
    private func signUp() {
        let phoneNumberKit = PhoneNumberKit()
        do {
            let phoneNumber = try phoneNumberKit.parse(self.phoneNumber)
            let formattedPhoneNumber = phoneNumberKit.format(phoneNumber, toType: .e164)
            print("Formatted Phone Number: \(formattedPhoneNumber)")
            
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    return
                }
                
                guard let user = authResult?.user else {
                    self.alertMessage = "User not found"
                    self.showAlert = true
                    return
                }
                
                // Salva i dati dell'utente in Firestore
                let userData: [String: Any] = [
                    "email": self.email,
                    "password":self.password,
                    "Name": self.Name,
                    "Surname":self.Surname,
                    "phoneNumber": formattedPhoneNumber,
                    "createdAt": Timestamp(date: Date())
                ]
                
                self.db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        self.alertMessage = "Error saving user data: \(error.localizedDescription)"
                        self.showAlert = true
                        return
                    }
                    
                    // Gestione della registrazione riuscita
                    self.isSignedUp = true
                }
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
        textField.withFlag = true
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

struct SignUpViewController_Previews: PreviewProvider {
    static var previews: some View {
        SignUpViewController()
    }
}
