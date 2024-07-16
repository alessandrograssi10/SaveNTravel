import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Charts


struct TripDetailView: View {
    @StateObject private var viewModel: TripDetailViewModel

    init(tripCode: String) {
        _viewModel = StateObject(wrappedValue: TripDetailViewModel(tripCode: tripCode))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let tripDetails = viewModel.tripDetails {
                    HStack {
                        BudgetPieChartView(categories: tripDetails.categories, totalBudget: tripDetails.totalBudget)
                            .frame(width: 150, height: 150)

                        VStack(alignment: .leading) {
                            Text("Trip Details")
                                .font(.title)
                                .padding(.bottom, 5)

                            Text("Destination: \(tripDetails.destination)")
                                .font(.subheadline)
                                .padding(.bottom, 1)

                            Text("Total Budget: \(Int(tripDetails.totalBudget))")
                                .font(.subheadline)
                                .padding(.bottom, 1)

                            Text("Participants: \(viewModel.participants.count)")
                                .font(.subheadline)
                                .padding(.bottom, 1)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)

                    // Total budget progress bar
                    VStack(alignment: .leading) {
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 40)
                                .cornerRadius(5)

                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: CGFloat(viewModel.calculateTotalRemainingProgress()) * (UIScreen.main.bounds.width - 40), height: 40)
                                .cornerRadius(5)

                            HStack {
                                            Text("Total")
                                                .font(.headline.bold())
                                                .foregroundColor(.white)
                                                .padding(5)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 5)
                                                        .fill(Color.blue)
                                                )
                                                .padding(.leading, 10)

                                            Spacer()

                                            Text("\(1000) di \(2000)")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(5)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 5)
                                                        .fill(Color.blue)
                                                )
                                                .padding(.trailing, 10)
                                        }
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(height: 40)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                    // Categories list with progress bars
                    if tripDetails.categories.isEmpty {
                        Text("No categories available")
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(tripDetails.categories) { category in
                                VStack(alignment: .leading) {
                                    HStack {
                                        RoundedRectangle(cornerRadius: 105)
                                            .fill(Color(hex: category.color) ?? .black)
                                            .frame(width: 10, height: 10)

                                        Text(category.name)
                                            .font(.caption)
                                            .foregroundColor(.black)
                                            .padding(.leading, 2)
                                    }
                                    .padding(.horizontal, 20)

                                    // Progress bar for each category
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(height: 20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 5)
                                                    .stroke(Color(hex: category.color) ?? .black, lineWidth: 2)
                                            )

                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color(hex: category.color) ?? .green)
                                            .frame(width: CGFloat(viewModel.calculateCategoryRemainingProgress(category: category)) * (UIScreen.main.bounds.width - 40), height: 20)

                                        HStack {
                                            Spacer()
                                            Text("\(Int(viewModel.calculateCategoryRemainingBudget(category: category))) di \(Int(category.budget))")
                                                .font(.caption)
                                                .foregroundColor(.black)
                                                .padding(.trailing, 10)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                                .padding(.bottom, 10)
                            }
                        }
                    }

                    // Participants section
                    if !viewModel.participants.isEmpty {
                        Text("Participants")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.participants) { participant in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            let displayName = participant.email == Auth.auth().currentUser?.email ? "You" : "\(participant.name) \(participant.surname)"
                                            Text(displayName)
                                                .font(.footnote)
                                                .padding(5)
                                                .background(Color.blue.opacity(0))
                                                .cornerRadius(10)
                                        }

                                        // Place FriendshipStatusView to the right if not the current user
                                        if participant.email != Auth.auth().currentUser?.email {
                                            FriendshipStatusView(participant: participant, viewModel: viewModel)
                                        }
                                    }
                                    .padding(5)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        Text("No participants found")
                            .padding(.horizontal)
                            .padding(.top)
                    }

                    // Transactions section
                    VStack(alignment: .leading) {
                        Text("Transactions")
                            .font(.headline)
                            .padding(.top)
                            .padding(.horizontal)
                        Divider()

                        if viewModel.purchases.isEmpty {
                            Text("No transactions available")
                                .padding(.top, 4)
                                .padding(.horizontal)
                        } else {
                            ForEach(viewModel.purchases) { purchase in
                                VStack(alignment: .leading) {

                                    HStack {
                                        Circle()
                                            .fill(viewModel.colorForCategory(categoryName: purchase.category) ?? .black)
                                            .frame(width: 15, height: 15)
                                            .padding(.trailing, 10)

                                        VStack(alignment: .leading) {
                                            Text(purchase.name)
                                                .font(.headline)
                                            Text("\(purchase.category) ")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)

                                            Text(purchase.date, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Text("$\(String(format: "%.2f", purchase.price))")
                                            .font(.headline)
                                        

                                        Spacer()

                                        HStack {
                                            

                                            Button(action: {
                                                viewModel.deletePurchase(purchase)
                                            }) {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 5)
                                .padding(.horizontal)
                                Divider()
                            }
                        }
                    }

                    Spacer()
                } else {
                    Text("Loading trip details...")
                        .padding()
                }
            }
            .navigationBarTitle(viewModel.tripTitle, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let tripDetails = viewModel.tripDetails {
                        NavigationLink(destination: EditTripView(tripDetails: tripDetails, tripCode: viewModel.tripCode)) {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
            .onAppear {
                viewModel.fetchTripDetails()
                viewModel.loadFriendsRequests()
                viewModel.loadEstablishedFriends()
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Error"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

class TripDetailViewModel: ObservableObject {
    @Published var tripDetails: TripData?
    @Published var participants: [Participant] = []

    @Published var showAlert = false
    var alertMessage = ""
    @Published var tripTitle: String = ""
    @Published var purchases: [Purchase] = []

    private(set) var tripCode: String

    let db = Firestore.firestore()
    private var loadedFriendsEmails = Set<String>()
    @Published var friends: [Friend] = []
    @Published var sentFriendRequestsLoaded = false
    @Published var receivedFriendRequestsLoaded = false
    @Published var establishedFriendsLoaded = false
    var currentUserEmail: String {
        Auth.auth().currentUser?.email?.lowercased() ?? ""
    }

    init(tripCode: String) {
        self.tripCode = tripCode
    }

    func fetchTripDetails() {
        guard let user = Auth.auth().currentUser else {
            self.alertMessage = "User not logged in."
            self.showAlert = true
            print(alertMessage)
            return
        }
        
        let tripRef = db.collection("trips").document(tripCode)

        tripRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            if let error = error {
                self.alertMessage = "Error fetching trip details: \(error.localizedDescription)"
                self.showAlert = true
                print(self.alertMessage)
                return
            }

            guard let document = document, document.exists, let data = document.data() else {
                self.alertMessage = "No trip details found for the given trip code."
                self.showAlert = true
                print(self.alertMessage)
                return
            }

            // Fetch participant emails
            print("UTENTI", data["users"] as? [String])
            if let participantEmails = data["users"] as? [String] {
                self.fetchParticipantsDetails(emails: participantEmails)
            }

            // Fetch budget and categories from users->trip->budget
            let userTripRef = self.db.collection("users").document(user.uid).collection("trips").document(self.tripCode)

            userTripRef.getDocument { [weak self] (budgetDoc, error) in
                guard let self = self else { return }
                if let error = error {
                    self.alertMessage = "Error fetching budget details: \(error.localizedDescription)"
                    self.showAlert = true
                    print(self.alertMessage)
                    return
                }

                guard let budgetDoc = budgetDoc, budgetDoc.exists, let budgetData = budgetDoc.data() else {
                    self.alertMessage = "No budget details found for the given trip code."
                    self.showAlert = true
                    print(self.alertMessage)
                    return
                }

                // Debug: Print fetched budget data
                print("Budget document data: \(budgetData)")

                let categoriesData = budgetData["categories"] as? [[String: Any]] ?? []
                var categories: [Category] = []

                for categoryData in categoriesData {
                    guard
                        let name = categoryData["name"] as? String,
                        let colorString = categoryData["color"] as? String,
                        let budget = categoryData["budget"] as? Double
                    else {
                        continue
                    }
                    categories.append(Category(name: name, color: colorString, budget: budget))
                }

                let totalBudget = budgetData["totalBudget"] as? Double ?? 0.0

                let tripData = TripData(
                    destination: data["destination"] as? String ?? "",
                    totalBudget: totalBudget,
                    categories: categories,
                    timestamp: data["timestamp"] as? Timestamp ?? Timestamp(date: Date()),
                    participants: data["participants"] as? [String] ?? []
                )

                DispatchQueue.main.async {
                    self.tripDetails = tripData
                    self.tripTitle = tripData.destination
                    print("Fetched trip details: \(tripData)")
                    self.fetchPurchases()
                }
            }
        }
    }

    private func fetchParticipantsDetails(emails: [String]) {
        let usersRef = db.collection("users")
        let dispatchGroup = DispatchGroup()
        var newParticipants: [Participant] = []

        for email in emails {
            dispatchGroup.enter()
            // First, find the document ID using the email
            usersRef.whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error fetching user ID for \(email): \(error.localizedDescription)")
                    dispatchGroup.leave()
                    return
                }

                guard let documents = querySnapshot?.documents, let document = documents.first else {
                    print("No user ID found for \(email)")
                    dispatchGroup.leave()
                    return
                }

                let userDocID = document.documentID
                print("Fetched userDocID for \(email): \(userDocID)") // Debug statement

                // Now fetch the user's details using the document ID
                usersRef.document(userDocID).getDocument { (userDoc, error) in
                    if let error = error {
                        print("Error fetching user details for \(email): \(error.localizedDescription)")
                        dispatchGroup.leave()
                        return
                    }

                    guard let userDoc = userDoc, userDoc.exists, let data = userDoc.data() else {
                        print("No user details found for \(email)")
                        dispatchGroup.leave()
                        return
                    }

                    print("Fetched data for \(email): \(data)") // Debug statement

                    let name = data["Name"] as? String ?? ""
                    let surname = data["Surname"] as? String ?? ""

                    if name.isEmpty || surname.isEmpty {
                        print("Warning: Missing name or surname for \(email)")
                    }

                    let participant = Participant(email: email, name: name, surname: surname)
                    print("Fetched participant: \(participant)") // Debug statement
                    newParticipants.append(participant)
                    dispatchGroup.leave()
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            self.participants = newParticipants
            print("Participants array updated: \(self.participants)") // Debug statement
        }
    }


    func fetchPurchases() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }

        db.collection("users").document(userID).collection("trips").document(tripCode).collection("purchases").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching purchases: \(error.localizedDescription)")
                return
            }

            var purchasesList: [Purchase] = []

            for document in querySnapshot!.documents {
                do {
                    let purchase = try document.data(as: Purchase.self)
                    purchasesList.append(purchase)
                } catch {
                    print("Error decoding purchase: \(error.localizedDescription)")
                }
            }

            DispatchQueue.main.async {
                self.purchases = purchasesList.sorted(by: { $0.timestamp.seconds > $1.timestamp.seconds })
            }
        }
    }

    // Calculate remaining budget progress for the total budget
    func calculateTotalRemainingProgress() -> Double {
        guard let tripDetails = tripDetails else { return 0.0 }
        let spent = purchases.reduce(0) { $0 + $1.price }
        let remaining = tripDetails.totalBudget - spent
        return remaining / tripDetails.totalBudget
    }
    
    // Calculate the remaining budget for the total budget
    func calculateTotalRemainingBudget() -> Double {
        guard let tripDetails = tripDetails else { return 0.0 }
        let spent = purchases.reduce(0) { $0 + $1.price }
        return tripDetails.totalBudget - spent
    }

    // Calculate remaining budget progress for each category
    func calculateCategoryRemainingProgress(category: Category) -> Double {
        let spent = purchases.filter { $0.category == category.name }.reduce(0) { $0 + $1.price }
        let remaining = category.budget - spent
        return remaining / category.budget
    }
    
    // Calculate the remaining budget for each category
    func calculateCategoryRemainingBudget(category: Category) -> Double {
        let spent = purchases.filter { $0.category == category.name }.reduce(0) { $0 + $1.price }
        return category.budget - spent
    }

    // Calculate remaining budget progress for the "Others" category
    func calculateOthersRemainingProgress() -> Double {
        guard let othersCategory = tripDetails?.categories.first(where: { $0.name == "Others" }) else { return 0.0 }
        let spent = purchases.filter { purchase in
            purchase.category == "Others" || !tripDetails!.categories.contains(where: { $0.name == purchase.category })
        }.reduce(0) { $0 + $1.price }
        let remaining = othersCategory.budget - spent
        return remaining / othersCategory.budget
    }
    
    // Calculate the remaining budget for the "Others" category
    func calculateOthersRemainingBudget() -> Double {
        guard let othersCategory = tripDetails?.categories.first(where: { $0.name == "Others" }) else { return 0.0 }
        let spent = purchases.filter { purchase in
            purchase.category == "Others" || !tripDetails!.categories.contains(where: { $0.name == purchase.category })
        }.reduce(0) { $0 + $1.price }
        return othersCategory.budget - spent
    }

    // Calculate the budget for the "Others" category
    func calculateOthersBudget() -> Double {
        return tripDetails?.categories.first(where: { $0.name == "Others" })?.budget ?? 0.0
    }

    // Helper method to get the color for a category
    func colorForCategory(categoryName: String) -> Color? {
        guard let tripDetails = tripDetails else { return nil }
        return tripDetails.categories.first { $0.name == categoryName }?.color.hexToColor()
    }

    // Methods to edit and delete purchases
    func editPurchase(_ purchase: Purchase) {
        // Implement the logic to edit the purchase
    }

    func deletePurchase(_ purchase: Purchase) {
        // Implement the logic to delete the purchase
    }

    // Friend request management
    func loadFriendsRequests() {
        guard !currentUserEmail.isEmpty else {
            return
        }

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

                    if !self.loadedFriendsEmails.contains(toEmail) {
                        let friend = Friend(name: "", surname: "", email: toEmail, pending: true, requestType: .sent)
                        newFriends.append(friend)
                        self.loadedFriendsEmails.insert(toEmail)
                    }
                }

                DispatchQueue.main.async {
                    self.friends.append(contentsOf: newFriends)
                    self.sentFriendRequestsLoaded = true
                }
            }

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

                    if !self.loadedFriendsEmails.contains(fromEmail) {
                        let friend = Friend(name: "", surname: "", email: fromEmail, pending: true, requestType: .received)
                        newFriends.append(friend)
                        self.loadedFriendsEmails.insert(fromEmail)
                    }
                }

                DispatchQueue.main.async {
                    self.friends.append(contentsOf: newFriends)
                    self.receivedFriendRequestsLoaded = true
                }
            }
    }

    func loadEstablishedFriends() {
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
                }
            }
    }

    func getFriendshipStatus(for email: String, completion: @escaping (FriendRequestType?) -> Void) {
        if let friend = friends.first(where: { $0.email.lowercased() == email.lowercased() }) {
            completion(friend.requestType)
        } else {
            completion(nil)
        }
    }

    func sendFriendRequest(to email: String) {
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            return
        }

        let friendRequestData: [String: Any] = [
            "from": currentUserEmail,
            "to": email,
            "status": "pending"
        ]

        db.collection("friendRequests").addDocument(data: friendRequestData) { error in
            if let error = error {
                print("Error sending friend request: \(error.localizedDescription)")
            } else {
                print("Friend request sent to \(email)")
                self.reloadData() // Call reloadData after sending the friend request
                print("Data reloaded after sending friend request")
            }
        }
    }

    public func reloadData() {
        fetchTripDetails()
        loadFriendsRequests()
        loadEstablishedFriends()
    }

}

struct FriendshipStatusView: View {
    let participant: Participant
    @ObservedObject var viewModel: TripDetailViewModel
    @State private var status: FriendRequestType?

    var body: some View {
        HStack {
            if let status = status {
                switch status {
                case .sent:
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                case .received:
                    Image(systemName: "clock.fill")
                        .foregroundColor(.yellow)
                case .established:
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                }
            } else {
                Button(action: {
                    viewModel.sendFriendRequest(to: participant.email)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        viewModel.getFriendshipStatus(for: participant.email) { fetchedStatus in
                            self.status = fetchedStatus
                        }
                    }
                }) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            viewModel.getFriendshipStatus(for: participant.email) { fetchedStatus in
                self.status = fetchedStatus
            }
        }
    }
}

extension String {
    func hexToColor() -> Color? {
        let r, g, b, a: Double
        let start = self.hasPrefix("#") ? self.index(self.startIndex, offsetBy: 1) : self.startIndex
        let hexColor = String(self[start...])
        
        if hexColor.count == 8 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = Double((hexNumber & 0xff000000) >> 24) / 255
                g = Double((hexNumber & 0x00ff0000) >> 16) / 255
                b = Double((hexNumber & 0x0000ff00) >> 8) / 255
                a = Double(hexNumber & 0x000000ff) / 255
                
                return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
            }
        }
        return nil
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r, g, b, a: Double
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

struct TripDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TripDetailView(tripCode: "AOKQN")
        }
    }
}

////
///


