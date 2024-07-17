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
}

struct FriendView: View {
    let friend: Friend
    let onAccept: () -> Void
    
    @State private var splits: [Split] = []
    @State private var totalCredits = 0
    @State private var totalDebits = 0
    @State private var showingPaymentOptions = false
    @State private var selectedPaymentOption = 0
    @State private var hasTransactions = true // Aggiunto stato per verificare se ci sono transazioni
    
    private let db = Firestore.firestore()
    
    private var currentUserEmail: String {
        Auth.auth().currentUser?.email?.lowercased() ?? ""
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("\(friend.name) \(friend.surname)")
                        .font(.subheadline)
                    
                    Spacer()
                    
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
                    }
                }
                .padding(.horizontal)
                
                // Mostra messaggi informativi se non ci sono transazioni
                if splits.isEmpty {
                    VStack {
                        Text("No transactions yet")
                            .font(.title)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 20)
                        
                        Text("Start splitting expenses with \(friend.email)!")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Mostra "transactions with email" se specificato
                    if !friend.email.isEmpty {
                        Text("Transactions with \(friend.email)")
                            .font(.headline)
                            .padding(.horizontal)
                    }
                    
                    List(splits) { split in
                        SplitRowView(split: split, currentUserEmail: currentUserEmail, friendEmail: friend.email, showPaymentOptions: $showingPaymentOptions)
                    }
                    .listStyle(InsetGroupedListStyle())
                    .padding(.top, 10)
                    
                    // Calcolo del totale (crediti - debiti)
                    let netTotal = totalCredits - totalDebits
                    HStack {
                        Text("Net Total: \(netTotal)")
                            .font(.headline)
                            .padding()
                        
                        Spacer()
                        
                        if netTotal < 0 {
                            Button(action: {
                                // Azione per pagare tutti i debiti
                            }) {
                                Text("Pay all debts")
                                    .foregroundColor(.red)
                                    .font(.footnote)
                            }
                            .padding(.trailing, 10)
                        } else if netTotal > 0 {
                            Button(action: {
                                // Azione per richiedere tutti i pagamenti
                            }) {
                                Text("Request all payments")
                                    .foregroundColor(.blue)
                                    .font(.footnote)
                            }
                            .padding(.trailing, 10)
                        }
                    }
                }
            }
            .padding(.vertical)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding(.horizontal)
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
                    self.hasTransactions = false // Imposta hasTransactions a false se non ci sono documenti
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
                          let tripCode = data["tripCode"] as? String else {
                        return nil
                    }

                    return Split(id: document.documentID, authoredBy: authoredBy, category: category, name: name, price: price, sharedWith: sharedWith, timestamp: timestamp, tripCode: tripCode)
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
                          let tripCode = data["tripCode"] as? String else {
                        return nil
                    }

                    return Split(id: document.documentID, authoredBy: authoredBy, category: category, name: name, price: price, sharedWith: sharedWith, timestamp: timestamp, tripCode: tripCode)
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
}

struct SplitRowView: View {
    let split: Split
    let currentUserEmail: String
    let friendEmail: String
    @Binding var showPaymentOptions: Bool
    @State private var selectedPaymentOption = 0
    
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
                
                Text("Trip Code: \(split.tripCode)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if split.authoredBy == friendEmail && split.sharedWith.contains(currentUserEmail) {
                    Text("Debit")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                    Button(action: {
                        self.showPaymentOptions.toggle()
                    }) {
                        Text("Select Payment Option")
                            .foregroundColor(.blue)
                    }
                    .actionSheet(isPresented: $showPaymentOptions) {
                        ActionSheet(title: Text("Select Payment Option"), buttons: [
                            .default(Text("Pay with Apple Pay")) {
                                // Azione per pagare con Apple Pay
                                self.selectedPaymentOption = 1
                            },
                            .default(Text("Pay with Cash")) {
                                // Azione per pagare in contanti
                                self.selectedPaymentOption = 2
                            },
                            .destructive(Text("Was not me")) {
                                // Azione per segnalare che non sei stato tu
                                self.selectedPaymentOption = 3
                            },
                            .cancel()
                        ])
                    }
                } else if split.authoredBy == currentUserEmail && split.sharedWith.contains(friendEmail) {
                    Text("Credit")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                    Button(action: {
                        // Azione per richiedere il pagamento
                    }) {
                        Text("Request Payment")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.top, 5)
        }
        .padding(.vertical, 10)
    }
}

