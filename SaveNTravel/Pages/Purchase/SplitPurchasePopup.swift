
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SplitPurchasePopup: View {
    @Binding var showPopup: Bool
    @State private var nomeSpesa: String = ""
    @State private var category: String = ""
    @State private var amount: String = ""
    @State private var categories: [Category] = []
    @State private var friends: [User] = []
    @State private var selectedFriends: Set<String> = []
    @State private var userTrips: [Trip] = []
    @State private var selectedTrip: Trip? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var userID: String? = nil
    @State private var userEmail: String? = nil
    @State private var tripCategories: [Category] = []
    @State private var selectedCategory: Category? = nil

    @EnvironmentObject var purchaseViewModel: PurchaseViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    let db = Firestore.firestore()

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Button(action: {
                            showPopup = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)
                                .padding()
                        }
                        Spacer()
                    }
                    .padding(.top)
                    
                    Text("SPLIT PURCHASE")
                        .font(.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                    
                    TextField("Enter title of expense", text: $nomeSpesa)
                        .font(.title3)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.vertical)
                    
                    Text("SELECT TRIP")
                        .font(.headline)
                        .bold()
                        .padding(.leading)
                    
                    Menu {
                        ForEach(userTrips) { trip in
                            Button(action: {
                                selectedTrip = trip
                                fetchCategories(for: trip)
                                fetchFriends(for: trip)
                            }) {
                                Text(trip.title)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedTrip?.title ?? "Select a trip")
                                .foregroundColor(selectedTrip == nil ? Color(UIColor.placeholderText) : .black)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.vertical)
                    
                    // CATEGORY Section
                    if !tripCategories.isEmpty && !friends.isEmpty {
                        Text("CATEGORY")
                            .font(.headline)
                            .bold()
                            .padding(.leading)
                        
                        VStack {
                            ForEach(tripCategories) { category in
                                RadioButtonField(id: category.id, label: category.name, isMarked: selectedCategory?.id == category.id) { selectedId in
                                    if let selectedCat = tripCategories.first(where: { $0.id == selectedId }) {
                                        selectedCategory = selectedCat
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // SELECT FRIENDS Section
                    if let _ = selectedTrip?.code {
                        if !friends.isEmpty {
                            Text("SELECT FRIENDS")
                                .font(.headline)
                                .bold()
                                .padding(.leading)
                                .padding(.top)
                            
                            List(friends, id: \.email) { friend in
                                MultipleSelectionRow(title: friend.name, isSelected: selectedFriends.contains(friend.email)) {
                                    if selectedFriends.contains(friend.email) {
                                        selectedFriends.remove(friend.email)
                                    } else {
                                        selectedFriends.insert(friend.email)
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            .frame(height: 150)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            
                            // INSERT AMOUNT Section
                            Text("INSERT AMOUNT")
                                .font(.headline)
                                .bold()
                                .padding(.leading)
                                .padding(.top)
                            
                            TextField("Enter amount", text: $amount)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            
                            Spacer()
                            
                            Button(action: {
                                if let userID = userID, let userEmail = userEmail, let trip = selectedTrip, let category = selectedCategory, let price = Double(amount) {
                                    let totalParticipants = selectedFriends.count + 1
                                    let splitAmount = price / Double(totalParticipants)
                                    let newPurchase = Purchase(name: nomeSpesa, category: category.name, price: splitAmount, sharedWith: Array(selectedFriends), authoredBy: userEmail)
                                    
                                    // Debug print statements
                                    print("UserID: \(userID)")
                                    print("UserEmail: \(userEmail)")
                                    print("Selected Trip: \(trip)")
                                    print("Selected Category: \(category)")
                                    print("Price: \(price)")
                                    print("Split Amount: \(splitAmount)")
                                    print("Selected Friends: \(selectedFriends)")
                                    
                                    purchaseViewModel.addPurchase(newPurchase, userID: userID, tripCode: trip.code)
                                    addSplit(newPurchase: newPurchase, userID: userID, tripCode: trip.code)
                                    showPopup = false
                                }
                            }) {
                                Text("Done")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .opacity(friends.isEmpty ? 0.5 : 1.0)
                                    .disabled(friends.isEmpty)
                            }
                            .padding()

                            
                        } else {
                            Text(" ")
                            Text("0 available people to split payment with")
                                .padding(.leading)
                                .font(.headline)
                                .foregroundColor(Color(UIColor.placeholderText))
                        }
                    } else {
                        Text(" ")
                        Text("You must select a trip")
                            .padding(.leading)
                            .font(.headline)
                            .foregroundColor(Color(UIColor.placeholderText))
                    }
                    
                }
                .padding()
                .onAppear {
                    fetchUserEmail()
                    fetchUserTrips()
                }
            }
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .navigationBarTitle("", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }



    struct RadioButtonField: View {
        let id: String
        let label: String
        let isMarked: Bool
        let callback: (String) -> ()

        var body: some View {
            Button(action: {
                self.callback(self.id)
            }) {
                HStack {
                    Text(self.label)
                        .font(.body)
                        .bold()
                    Spacer()
                    if self.isMarked {
                        Image(systemName: "largecircle.fill.circle")
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(35)
            }
        }
    }

    private func fetchUserEmail() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not logged in."
            showAlert = true
            return
        }
        userEmail = user.email
    }

    private func fetchUserTrips() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not logged in."
            showAlert = true
            return
        }

        userID = user.uid

        db.collection("users").document(user.uid).getDocument { (document, error) in
            if let error = error {
                alertMessage = "Error fetching user data: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            guard let document = document, document.exists else {
                alertMessage = "User document does not exist."
                showAlert = true
                return
            }

            let data = document.data()
            if let tripCodes = data?["trips"] as? [String] {
                fetchTrips(tripCodes: tripCodes)
            } else {
                alertMessage = "No trips found for user."
                showAlert = true
            }
        }
    }

    private func fetchTrips(tripCodes: [String]) {
        let dispatchGroup = DispatchGroup()
        var fetchedTrips: [Trip] = []

        for tripCode in tripCodes {
            dispatchGroup.enter()
            db.collection("trips").document(tripCode).getDocument { (document, error) in
                if let error = error {
                    print("Error fetching trip data for trip code \(tripCode): \(error.localizedDescription)")
                    alertMessage = "Error fetching trip data: \(error.localizedDescription)"
                    showAlert = true
                    dispatchGroup.leave()
                    return
                }
                
                guard let document = document, document.exists else {
                    print("Trip document does not exist for trip code \(tripCode)")
                    alertMessage = "Trip document does not exist for trip code \(tripCode)"
                    showAlert = true
                    dispatchGroup.leave()
                    return
                }
                
                let data = document.data()
                if let destination = data?["destination"] as? String,
                   let timestamp = data?["timestamp"] as? Timestamp {
                    let trip = Trip(
                        imageName: data?["imageName"] as? String ?? "defaultImage",
                        title: destination,
                        description: data?["description"] as? String ?? "This is a trip description",
                        code: tripCode,
                        timestamp: timestamp
                    )
                    fetchedTrips.append(trip)
                } else {
                    print("Invalid trip data format for trip code \(tripCode)")
                    alertMessage = "Invalid trip data format for trip code \(tripCode)"
                    showAlert = true
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.userTrips = fetchedTrips
            print("Fetched trips: \(self.userTrips)") // Debug log
        }
    }

    private func fetchCategories(for trip: Trip) {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not logged in."
            showAlert = true
            return
        }

        userID = user.uid

        db.collection("users").document(user.uid).collection("trips").document(trip.code).getDocument { (document, error) in
            if let error = error {
                alertMessage = "Error fetching trip categories: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            guard let document = document, document.exists else {
                alertMessage = "Trip document does not exist for selected trip."
                showAlert = true
                return
            }

            do {
                if let categoriesData = document.data()?["categories"] as? [[String: Any]] {
                    var decodedCategories: [Category] = []
                    for categoryData in categoriesData {
                        if let jsonData = try? JSONSerialization.data(withJSONObject: categoryData),
                           let category = try? JSONDecoder().decode(Category.self, from: jsonData) {
                            decodedCategories.append(category)
                        }
                    }
                    tripCategories = decodedCategories
                } else {
                    alertMessage = "Categories data is not in the expected format."
                    showAlert = true
                }
            } catch {
                alertMessage = "Error decoding trip data: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    private func fetchFriends(for trip: Trip) {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not logged in."
            showAlert = true
            return
        }

        userID = user.uid

        db.collection("trips").document(trip.code).getDocument { (document, error) in
            if let error = error {
                alertMessage = "Error fetching friends data: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                alertMessage = "Friends document does not exist for selected trip."
                showAlert = true
                return
            }

            let participantEmails = data["users"] as? [String] ?? []
            let filteredParticipantEmails = participantEmails.filter { $0 != user.email }
            print("Filtered participant emails: \(filteredParticipantEmails)") // Debug log
            
            fetchUserDetails(for: filteredParticipantEmails)
        }
    }

    private func fetchUserDetails(for emails: [String]) {
        let dispatchGroup = DispatchGroup()
        var fetchedFriends: [User] = []

        for email in emails {
            dispatchGroup.enter()
            db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching user details for email \(email): \(error.localizedDescription)")
                    dispatchGroup.leave()
                    return
                }
                
                guard let documents = querySnapshot?.documents, let document = documents.first else {
                    print("No user document found for email \(email)")
                    dispatchGroup.leave()
                    return
                }
                
                if let user = User(document: document) {
                    print("User found: \(user)") // Debug log
                    
                    // Check if friend request is accepted and user is participant of the trip
                    self.checkFriendRequestExists(from: user.email, to: Auth.auth().currentUser!.email!) { result in
                        switch result {
                        case .success(let status):
                            if status == "already friend" {
                                fetchedFriends.append(user)
                                print("Friend added: \(user)") // Debug log
                            }
                        case .failure(let error):
                            print("Error checking friend request for \(user.email): \(error.localizedDescription)")
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            // Fetch participants for the trip
            self.fetchParticipants(for: emails, friends: fetchedFriends)
        }
    }

    private func fetchParticipants(for emails: [String], friends: [User]) {
        let dispatchGroup = DispatchGroup()
        var participants: [Participant] = []

        // Debug: Print friend emails
        let friendEmails = friends.map { $0.email }
        print("Friend emails: \(friendEmails)")

        for email in emails {
            dispatchGroup.enter()
            db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching participant details for email \(email): \(error.localizedDescription)")
                    dispatchGroup.leave()
                    return
                }
                
                guard let documents = querySnapshot?.documents, let document = documents.first else {
                    print("No participant document found for email \(email)")
                    dispatchGroup.leave()
                    return
                }
                
                let data = document.data()
                let email = document["email"] as? String ?? ""
                let name = data["name"] as? String ?? "Unknown"
                let surname = data["surname"] as? String ?? "Unknown"
                
                let participant = Participant(email: email, name: name, surname: surname)
                participants.append(participant)
                print("Participant added: \(participant)") // Debug log
                
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            // Debug: Print participant emails
            let participantEmails = participants.map { $0.email }
            print("Participant emails: \(participantEmails)")

            // Filter friends who are also participants
            let commonEmails = Set(friendEmails).intersection(Set(participantEmails))
            let friendsInTrip = friends.filter { commonEmails.contains($0.email) }
            
            self.friends = friendsInTrip
            print("Fetched friends: \(self.friends)") // Debug log
        }
    }

    func checkFriendRequestExists(from currentUserEmail: String, to userEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Check if there is a friend request where currentUserEmail is in "from" and userEmail is in "to"
        db.collection("friendRequests")
            .whereField("from", isEqualTo: currentUserEmail)
            .whereField("to", isEqualTo: userEmail)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.checkReverseFriendRequestExists(from: currentUserEmail, to: userEmail, completion: completion)
                    return
                }
                
                if documents.isEmpty {
                    self.checkReverseFriendRequestExists(from: currentUserEmail, to: userEmail, completion: completion)
                } else if let document = documents.first, let status = document.data()["status"] as? String {
                    if status == "accepted" {
                        completion(.success("already friend")) // Già amici
                    } else {
                        self.checkReverseFriendRequestExists(from: currentUserEmail, to: userEmail, completion: completion)
                    }
                } else {
                    self.checkReverseFriendRequestExists(from: currentUserEmail, to: userEmail, completion: completion)
                }
            }
    }

    private func checkReverseFriendRequestExists(from currentUserEmail: String, to userEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Check if there is a friend request where userEmail is in "from" and currentUserEmail is in "to"
        db.collection("friendRequests")
            .whereField("from", isEqualTo: userEmail)
            .whereField("to", isEqualTo: currentUserEmail)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    completion(.success("add")) // Nessuna richiesta di amicizia trovata
                    return
                }
                
                if documents.isEmpty {
                    completion(.success("add")) // Nessuna richiesta di amicizia trovata
                } else if let document = documents.first, let status = document.data()["status"] as? String {
                    if status == "accepted" {
                        completion(.success("already friend")) // Già amici
                    } else {
                        completion(.success("add")) // Nessuna richiesta di amicizia trovata
                    }
                } else {
                    completion(.success("add")) // Nessuna richiesta di amicizia trovata
                }
            }
    }



    private func addSplit(newPurchase: Purchase, userID: String, tripCode: String) {
        let splitData: [String: Any] = [
            "authoredBy": newPurchase.authoredBy,
            "category": newPurchase.category,
            "name": newPurchase.name,
            "price": newPurchase.price,
            "sharedWith": newPurchase.sharedWith,
            "timestamp": Timestamp(date: Date()),
            "tripCode": tripCode
        ]

        db.collection("Splits").addDocument(data: splitData) { error in
            if let error = error {
                print("Error adding split: \(error.localizedDescription)")
                alertMessage = "Error adding split: \(error.localizedDescription)"
                showAlert = true
            } else {
                print("Split added successfully")
            }
        }
    }
}

struct MultipleSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack {
                Text(self.title)
                if self.isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

struct SplitPurchasePopup_Previews: PreviewProvider {
    static var previews: some View {
        SplitPurchasePopup(showPopup: .constant(true))
            .environmentObject(PurchaseViewModel())
            .environmentObject(AuthViewModel())
    }
}
