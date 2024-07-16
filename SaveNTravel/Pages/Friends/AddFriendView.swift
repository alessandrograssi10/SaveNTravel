import SwiftUI
import Firebase
import FirebaseFirestore

struct AddFriendView: View {
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isLoading = false
    @State private var showNoUsersFound = false
    @State private var requestStatus: [String: String] = [:] // Changed to String for status
    @StateObject private var friendRequestManager = FriendRequestManager()
    @Binding var friends: [Friend]
    @Environment(\.presentationMode) var presentationMode
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search by email", text: $searchText)
                    .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                List(searchResults) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.email)
                                .font(.headline)
                            Text("\(user.name) \(user.surname)")
                                .font(.subheadline)
                        }
                        Spacer()
                        
                        if let currentUserEmail = Auth.auth().currentUser?.email?.lowercased(), user.email.lowercased() == currentUserEmail {
                            Text("It's you!")
                                .foregroundColor(.gray)
                        } else {
                            if let status = requestStatus[user.email] {
                                switch status {
                                case "request sent":
                                    Text("Request Sent")
                                        .foregroundColor(.blue)
                                case "request received":
                                    Text("Request Received")
                                        .foregroundColor(.orange)
                                case "already friend":
                                    Text("Already Friend")
                                        .foregroundColor(.green)
                                default:
                                    Button(action: {
                                        guard let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() else {
                                            return
                                        }
                                        
                                        let userEmail = user.email
                                        
                                        friendRequestManager.sendFriendRequest(from: currentUserEmail, to: userEmail) { result in
                                            switch result {
                                            case .success:
                                                print("Request sent to \(userEmail)")
                                                requestStatus[userEmail] = "request sent"
                                            case .failure(let error):
                                                print("Error sending friend request: \(error.localizedDescription)")
                                            }
                                        }
                                    }) {
                                        Text("Add")
                                            .foregroundColor(.blue)
                                    }
                                }
                            } else if !isLoading {
                                Button(action: {
                                    guard let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() else {
                                        return
                                    }
                                    
                                    let userEmail = user.email
                                    
                                    friendRequestManager.sendFriendRequest(from: currentUserEmail, to: userEmail) { result in
                                        switch result {
                                        case .success:
                                            print("Request sent to \(userEmail)")
                                            requestStatus[userEmail] = "request sent"
                                        case .failure(let error):
                                            print("Error sending friend request: \(error.localizedDescription)")
                                        }
                                    }
                                }) {
                                    Text("Add")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .onAppear {
                        guard let currentUserEmail = Auth.auth().currentUser?.email?.lowercased() else {
                            return
                        }
                        
                        let userEmail = user.email
                        
                        if requestStatus[userEmail] == nil {
                            friendRequestManager.checkFriendRequestExists(from: currentUserEmail, to: userEmail) { result in
                                switch result {
                                case .success(let status):
                                    requestStatus[userEmail] = status
                                case .failure(let error):
                                    print("Error checking friend request: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                if searchResults.isEmpty && !isLoading && searchText.isEmpty {
                    Text("Start searching by entering an email")
                        .foregroundColor(.gray)
                        .padding()
                } else if searchResults.isEmpty && !isLoading {
                    Text("No users found")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarItems(trailing: Button("Done") {
                self.presentationMode.wrappedValue.dismiss()
            })
        }
        .onAppear {
            print("View appeared")
        }
        .onChange(of: searchText) { newValue in
            if searchText.isEmpty {
                searchResults.removeAll()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("Searching for users with email containing: \(searchText)")
                    searchUsers()
                }
            }
        }
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        
        let searchTextFormatted = searchText
        
        let query = db.collection("users")
            .whereField("email", isEqualTo: searchTextFormatted)
            .limit(to: 1)
        
        print("Executing query for email: \(searchTextFormatted)")
        
        query.getDocuments { querySnapshot, error in
            isLoading = false
            if let error = error {
                print("Error fetching users: \(error.localizedDescription)")
                searchResults = []
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                searchResults = []
                return
            }
            
            print("\(documents.count) documents found")
            
            if let userDocument = documents.first, let user = User(document: userDocument) {
                print("User found: \(user)")
                searchResults = [user]
            } else {
                print("No user found after parsing documents")
                searchResults = []
            }
        }
    }
}

