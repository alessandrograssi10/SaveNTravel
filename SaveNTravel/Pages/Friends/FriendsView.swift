import SwiftUI
import FirebaseFirestore
import FirebaseAuth


struct FriendsView: View {
    @State private var searchText = ""
    @State private var friends: [Friend] = []
    @State private var filteredFriends: [Friend] = []
    @State private var showAddFriendView = false
    @State private var loadedFriendsEmails = Set<String>()
    @State private var sentFriendRequestsLoaded = false
    @State private var receivedFriendRequestsLoaded = false
    @State private var establishedFriendsLoaded = false
    private var db = Firestore.firestore()
    private var currentUserEmail: String {
        Auth.auth().currentUser?.email?.lowercased() ?? ""
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.top, 10)
                    .onChange(of: searchText) { newValue in
                        filterFriends()
                    }
                
                List {
                    Section(header: Text("Established Friends")) {
                        ForEach(filteredFriends.filter {
                            !$0.pending && ($0.requestType == .established) && matchesSearchText($0.email, searchText: searchText)
                        }) { friend in
                            NavigationLink(destination: FriendView(friend: friend, onAccept: {
                                acceptFriendRequest(from: friend.email)
                            })) {
                                FriendRow(friend: friend)
                            }
                        }
                    }
                    
                    Section(header: Text("Friend Requests Sent")) {
                        ForEach(filteredFriends.filter {
                            $0.pending && ($0.requestType == .sent) && matchesSearchText($0.email, searchText: searchText)
                        }) { friend in
                            NavigationLink(destination: FriendView(friend: friend, onAccept: {
                                acceptFriendRequest(from: friend.email)
                            })) {
                                FriendRow(friend: friend)
                            }
                        }
                    }
                    
                    Section(header: Text("Friend Requests Received")) {
                        ForEach(filteredFriends.filter {
                            $0.pending && ($0.requestType == .received) && matchesSearchText($0.email, searchText: searchText)
                        }) { friend in
                            NavigationLink(destination: FriendView(friend: friend, onAccept: {
                                acceptFriendRequest(from: friend.email)
                            })) {
                                FriendRow(friend: friend)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Friends")
            .navigationBarItems(trailing:
                Button(action: {
                    showAddFriendView = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .imageScale(.large)
                }
            )
            .sheet(isPresented: $showAddFriendView) {
                AddFriendView(friends: $friends)
            }
            .onAppear {
                loadFriendsRequests()
                loadEstablishedFriends()
            }
        }
    }
    
    private func loadFriendsRequests() {
        guard !currentUserEmail.isEmpty else {
            return
        }
        
        // Carica le richieste di amicizia inviate
        if !sentFriendRequestsLoaded {
            db.collection("friendRequests")
                .whereField("from", isEqualTo: currentUserEmail)
                .whereField("status", isEqualTo: "pending")
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        print("Error loading sent friend requests: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("No documents found for sent friend requests")
                        return
                    }
                    
                    var newFriends: [Friend] = []
                    
                    for document in documents {
                        guard let toEmail = document.data()["to"] as? String else {
                            continue
                        }
                        
                        // Aggiungi solo se non è già stato caricato
                        if !loadedFriendsEmails.contains(toEmail) {
                            let friend = Friend(name: "", surname: "", email: toEmail, pending: true, requestType: .sent)
                            newFriends.append(friend)
                            loadedFriendsEmails.insert(toEmail)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.friends.append(contentsOf: newFriends)
                        self.sentFriendRequestsLoaded = true
                        self.filterFriends()
                    }
                }
        }
        
        // Carica le richieste di amicizia ricevute
        if !receivedFriendRequestsLoaded {
            db.collection("friendRequests")
                .whereField("to", isEqualTo: currentUserEmail.lowercased())
                .whereField("status", isEqualTo: "pending")
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        print("Error loading received friend requests: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("No documents found for received friend requests")
                        return
                    }
                    
                    var newFriends: [Friend] = []
                    
                    for document in documents {
                        guard let fromEmail = document.data()["from"] as? String else {
                            continue
                        }
                        
                        // Aggiungi solo se non è già stato caricato
                        if (!loadedFriendsEmails.contains(fromEmail)) {
                            let friend = Friend(name: "", surname: "", email: fromEmail, pending: true, requestType: .received)
                            newFriends.append(friend)
                            loadedFriendsEmails.insert(fromEmail)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.friends.append(contentsOf: newFriends)
                        self.receivedFriendRequestsLoaded = true
                        self.filterFriends()
                    }
                }
        }
    }
    
    private func loadEstablishedFriends() {
        guard !currentUserEmail.isEmpty else {
            return
        }
        
        db.collection("friendRequests")
            .whereField("status", isEqualTo: "accepted")
            .whereField("from", isEqualTo: currentUserEmail)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error loading established friends (from): \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found for established friends (from)")
                    return
                }
                
                var newFriends: [Friend] = []
                
                for document in documents {
                    guard let toEmail = document.data()["to"] as? String else {
                        continue
                    }
                    
                    if !self.loadedFriendsEmails.contains(toEmail) {
                        let friend = Friend(name: "", surname: "", email: toEmail, pending: false, requestType: .established)
                        newFriends.append(friend)
                        self.loadedFriendsEmails.insert(toEmail)
                    }
                }
                
                DispatchQueue.main.async {
                    self.friends.append(contentsOf: newFriends)
                    self.establishedFriendsLoaded = true
                    self.filterFriends()
                }
            }
        
        db.collection("friendRequests")
            .whereField("status", isEqualTo: "accepted")
            .whereField("to", isEqualTo: currentUserEmail)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error loading established friends (to): \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found for established friends (to)")
                    return
                }
                
                var newFriends: [Friend] = []
                
                for document in documents {
                    guard let fromEmail = document.data()["from"] as? String else {
                        continue
                    }
                    
                    if !self.loadedFriendsEmails.contains(fromEmail) {
                        let friend = Friend(name: "", surname: "", email: fromEmail, pending: false, requestType: .established)
                        newFriends.append(friend)
                        self.loadedFriendsEmails.insert(fromEmail)
                    }
                }
                
                DispatchQueue.main.async {
                    self.friends.append(contentsOf: newFriends)
                    self.establishedFriendsLoaded = true
                    self.filterFriends()
                }
            }
    }
    
    private func acceptFriendRequest(from email: String) {
        db.collection("friendRequests")
            .whereField("from", isEqualTo: email)
            .whereField("to", isEqualTo: currentUserEmail)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error accepting friend request: \(error.localizedDescription)")
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    print("No document found for the friend request to accept")
                    return
                }
                
                document.reference.updateData(["status": "accepted"]) { error in
                    if let error = error {
                        print("Error updating friend request status: \(error.localizedDescription)")
                    } else {
                        print("Friend request from \(email) accepted")
                        if let index = self.friends.firstIndex(where: { $0.email == email }) {
                            self.friends[index].pending = false
                            self.friends[index].requestType = .established
                            self.filterFriends()
                        }
                    }
                }
            }
    }
    
    private func filterFriends() {
        filteredFriends = friends.filter {
            !$0.pending && ($0.requestType == .established) && matchesSearchText($0.email, searchText: searchText) ||
            $0.pending && matchesSearchText($0.email, searchText: searchText)
        }
    }
    
    private func matchesSearchText(_ email: String, searchText: String) -> Bool {
        return searchText.isEmpty || email.localizedCaseInsensitiveContains(searchText)
    }
}


struct FriendRow: View {
    let friend: Friend
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(friend.email)")
                    .font(.headline)
                if !friend.pending {
                    Text("Established Friend")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    if friend.requestType == .sent {
                        Text("Friend Request Sent")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    } else if friend.requestType == .received {
                        Text("Friend Request Received")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct Friends_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
    }
}
