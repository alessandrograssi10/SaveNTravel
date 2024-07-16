import SwiftUI
import Firebase
import FirebaseFirestore
import UIKit



struct ProfilePageContent: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showEditProfile = false
    @State private var showChangePassword = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Profile Information")) {
                    ProfileInfoRow(label: "Name", value: authViewModel.displayName ?? "Unknown")
                    ProfileInfoRow(label: "Surname", value: authViewModel.userSurname ?? "Unknown")
                    ProfileInfoRow(label: "Email", value: authViewModel.userEmail ?? "Unknown")
                    ProfileInfoRow(label: "Mobile Phone", value: authViewModel.userPhoneNumber ?? "Unknown")
                }
                
                Section(header: Text("IBAN")) {
                    ProfileInfoRow(label: "IBAN", value: authViewModel.userIBAN ?? "Unknown")
                }
                
                Section {
                    NavigationLink(destination: EditProfileView().environmentObject(authViewModel)) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Profile")
                        }
                    }
                    
                    NavigationLink(destination: ChangePasswordView().environmentObject(authViewModel)) {
                        HStack {
                            Image(systemName: "lock")
                            Text("Change Password")
                        }
                    }
                    
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Sign Out")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Profile")
        }
    }
}


struct ProfileInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.semibold)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 5)
    }
}

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var displayName = ""
    @State private var userSurname = ""
    @State private var userEmail = ""
    @State private var userPhoneNumber = ""
    @State private var userIBAN = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Profile")) {
                    TextField("Display Name", text: $displayName)
                    TextField("Surname", text: $userSurname)
                    TextField("Email", text: $userEmail)
                    TextField("Mobile Phone", text: $userPhoneNumber)
                }
                
                Section(header: Text("IBAN")) {
                    TextField("IBAN", text: $userIBAN)
                }
                
                Button(action: {
                    authViewModel.updateUserData(field: "Name", value: displayName)
                    authViewModel.updateUserData(field: "Surname", value: userSurname)
                    authViewModel.updateUserData(field: "email", value: userEmail)
                    authViewModel.updateUserData(field: "phoneNumber", value: userPhoneNumber)
                    authViewModel.updateUserData(field: "IBAN", value: userIBAN)
                }) {
                    Text("Save")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Edit Profile")
            .onAppear {
                displayName = authViewModel.displayName ?? ""
                userSurname = authViewModel.userSurname ?? ""
                userEmail = authViewModel.userEmail ?? ""
                userPhoneNumber = authViewModel.userPhoneNumber ?? ""
                userIBAN = authViewModel.userIBAN ?? ""
            }
        }
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Change Password")) {
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                
                Button(action: {
                    if newPassword == confirmPassword {
                        Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
                            if let error = error {
                                print("Error updating password: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        print("Passwords do not match")
                    }
                }) {
                    Text("Change Password")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Change Password")
        }
    }
}

