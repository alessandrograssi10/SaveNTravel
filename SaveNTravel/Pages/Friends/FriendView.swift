import SwiftUI
import Firebase
import FirebaseFirestore

// Definizione del modello Split
struct Split: Identifiable {
    var id: String
    var authoredBy: String
    var category: String
    var name: String
    var price: Int
    var sharedWith: [String]
    var timestamp: Timestamp
    var tripCode: String
    var tripName: String
}

// Definizione della view FriendView
struct FriendView: View {
    let friend: Friend
    let onAccept: () -> Void
    
    @State private var splits: [Split] = []
    @State private var totalCredits = 0
    @State private var totalDebits = 0
    
    private let db = Firestore.firestore()
    
    private var currentUserEmail: String {
        Auth.auth().currentUser?.email?.lowercased() ?? ""
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("\(friend.name) \(friend.surname)")
                    .font(.subheadline)
                
                if friend.pending {
                    if friend.requestType == .sent {
                        Text("Request sent")
                            .foregroundColor(.orange)
                            .font(.footnote)
                    } else if friend.requestType == .received {
                        Button(action: onAccept) {
                            Text("Accept Friend Request")
                                .foregroundColor(.blue)
                                .font(.footnote)
                        }
                    }
                } else {
                    // Amicizia stabilita
                    List(splits) { split in
                        SplitRowView(split: split, currentUserEmail: currentUserEmail, friendEmail: friend.email)
                    }
                    .listStyle(InsetGroupedListStyle())
                    .padding(.top, 10)
                    
                    // Calcolo del totale (crediti - debiti)
                    let netTotal = totalCredits - totalDebits
                    HStack {
                        Text("Net Total: \(netTotal)")
                            .font(.headline)
                            .padding()
                        
                        if netTotal > 0 {
                            Button(action: requestAllCredits) {
                                Text("Request all credits")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                        } else if netTotal < 0 {
                            Button(action: payAllDebts) {
                                Text("Pay all debts")
                                    .foregroundColor(.red)
                            }
                            .padding()
                        }
                    }
                }
            }
            .padding()
            .navigationBarTitle("Friend Transactions", displayMode: .inline)
        }
        .onAppear {
            self.fetchSplits()
        }
    }
    
    // Metodo per recuperare i dati da Firestore
    private func fetchSplits() {
        print("Fetching splits for current user: \(currentUserEmail)")
        
        // Query per recuperare gli splits dove l'utente corrente è l'autore o è incluso in sharedWith
        db.collection("Splits")
            .whereField("authoredBy", isEqualTo: currentUserEmail)
            .whereField("sharedWith", arrayContains: friend.email)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching splits authored by current user: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                print("Number of splits fetched: \(documents.count)")
                
                // Mappatura dei documenti Firestore agli oggetti Split
                let splits = documents.compactMap { document -> Split? in
                    let data = document.data()

                    guard let authoredBy = data["authoredBy"] as? String,
                          let category = data["category"] as? String,
                          let name = data["name"] as? String,
                          let price = data["price"] as? Int,
                          let sharedWith = data["sharedWith"] as? [String],
                          let timestamp = data["timestamp"] as? Timestamp,
                          let tripCode = data["tripCode"] as? String,
                          let tripName = data["tripName"] as? String else {
                        return nil
                    }

                    return Split(id: document.documentID, authoredBy: authoredBy, category: category, name: name, price: price, sharedWith: sharedWith, timestamp: timestamp, tripCode: tripCode, tripName: tripName)
                }

                self.fetchSharedWithSplits(splits: splits)
            }
    }
    
    // Metodo per recuperare gli splits dove l'utente corrente è incluso in sharedWith
    private func fetchSharedWithSplits(splits: [Split]) {
        db.collection("Splits")
            .whereField("sharedWith", arrayContains: currentUserEmail)
            .whereField("authoredBy", isEqualTo: friend.email)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching splits where user is shared with: \(error)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found where user is shared with")
                    return
                }
                
                print("Number of shared splits fetched: \(documents.count)")
                
                let additionalSplits = documents.compactMap { document -> Split? in
                    let data = document.data()

                    guard let authoredBy = data["authoredBy"] as? String,
                          let category = data["category"] as? String,
                          let name = data["name"] as? String,
                          let price = data["price"] as? Int,
                          let sharedWith = data["sharedWith"] as? [String],
                          let timestamp = data["timestamp"] as? Timestamp,
                          let tripCode = data["tripCode"] as? String,
                          let tripName = data["tripName"] as? String else {
                        return nil
                    }

                    return Split(id: document.documentID, authoredBy: authoredBy, category: category, name: name, price: price, sharedWith: sharedWith, timestamp: timestamp, tripCode: tripCode, tripName: tripName)
                }

                var allSplits = splits
                allSplits.append(contentsOf: additionalSplits)
                
                self.calculateCreditsAndDebits(splits: allSplits)
            }
    }
    
    // Metodo per calcolare crediti e debiti
    private func calculateCreditsAndDebits(splits: [Split]) {
        print("Calculating credits and debits")
        
        totalCredits = 0
        totalDebits = 0
        
        for split in splits {
            if split.authoredBy == friend.email && split.sharedWith.contains(currentUserEmail) {
                totalDebits += split.price
                print("Added \(split.price) to totalDebits")
                print("\(currentUserEmail) owes \(friend.email) \(split.price)")
            }
            
            if split.authoredBy == currentUserEmail && split.sharedWith.contains(friend.email) {
                totalCredits += split.price
                print("Added \(split.price) to totalCredits")
                print("\(friend.email) owes \(currentUserEmail) \(split.price)")
            }
        }
        
        self.splits = splits
        print("Total Credits: \(totalCredits), Total Debits: \(totalDebits)")
    }
    
    // Metodo per richiedere tutti i crediti
    private func requestAllCredits() {
        print("Requesting all credits from \(friend.email)")
        // Implementa l'azione per richiedere tutti i crediti
    }
    
    // Metodo per pagare tutti i debiti
    private func payAllDebts() {
        print("Paying all debts to \(friend.email)")
        // Implementa l'azione per pagare tutti i debiti
    }
}

struct SplitRowView: View {
    let split: Split
    let currentUserEmail: String
    let friendEmail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(split.name)")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Category: \(split.category)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Price: \(split.price)")
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("In Trip: \(split.tripName)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if split.authoredBy == currentUserEmail && split.sharedWith.contains(friendEmail) {
                    Text("Credit")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                    Button(action: {
                        // Azione per richiedere il pagamento
                    }) {
                        Text("Request Payment")
                            .foregroundColor(.blue)
                    }
                } else if split.authoredBy == friendEmail && split.sharedWith.contains(currentUserEmail) {
                    Text("Debit")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                    Button(action: {
                        // Azione per pagare ora
                    }) {
                        Text("Pay Now")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.top, 5)
        }
        .padding(.vertical, 10)
    }
}

