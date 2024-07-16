import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var displayName: String?
    @Published var userEmail: String?
    @Published var userPhoneNumber: String?
    @Published var userSurname: String?
    @Published var userIBAN: String?
    
    private var db = Firestore.firestore()
    private var authListenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        checkUserAuthentication()
    }

    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }

            self?.isSignedIn = true
            self?.displayName = authResult?.user.displayName
            self?.userEmail = authResult?.user.email
            self?.fetchUserData()
            completion(true, nil)
        }
    }

    func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }

            if let document = document, document.exists {
                let userData = document.data()
                self?.displayName = userData?["Name"] as? String ?? "No Name"
                self?.userPhoneNumber = userData?["phoneNumber"] as? String ?? "No Phone Number"
                self?.userSurname = userData?["Surname"] as? String ?? "No Surname"
                self?.userIBAN = userData?["IBAN"] as? String ?? "No IBAN"
            } else {
                print("User document does not exist")
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            isSignedIn = false
            displayName = nil
            userEmail = nil
            userPhoneNumber = nil
            userSurname = nil
            userIBAN = nil
            print("User signed out successfully")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    private func checkUserAuthentication() {
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.isSignedIn = true
                self?.displayName = user.displayName
                self?.userEmail = user.email
                self?.fetchUserData()
            } else {
                self?.isSignedIn = false
                self?.displayName = nil
                self?.userEmail = nil
                self?.userPhoneNumber = nil
                self?.userSurname = nil
                self?.userIBAN = nil
            }
        }
    }

    func updateUserData(field: String, value: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userId).updateData([
            field: value
        ]) { error in
            if let error = error {
                print("Error updating user data: \(error.localizedDescription)")
            } else {
                print("User data updated successfully")
                // Update local properties if needed
                switch field {
                    case "Name": self.displayName = value
                    case "Surname": self.userSurname = value
                    case "email": self.userEmail = value
                    case "phoneNumber": self.userPhoneNumber = value
                    case "IBAN": self.userIBAN = value
                    default: break
                }
            }
        }
    }
}

