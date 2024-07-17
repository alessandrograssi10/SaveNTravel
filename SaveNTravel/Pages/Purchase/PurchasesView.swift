import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PurchasesView: View {
    @EnvironmentObject var purchaseViewModel: PurchaseViewModel
    @State private var purchases: [Purchase] = []

    var body: some View {
        NavigationView {
            List {
                ForEach(groupedPurchases.keys.sorted(), id: \.self) { tripName in
                    Section(header: Text(tripName)) {
                        ForEach(groupedPurchases[tripName] ?? []) { purchase in
                            if purchase.type == "Split" {
                                NavigationLink(destination: PurchaseDetailView(purchase: purchase)) {
                                    PurchaseRow(purchase: purchase)
                                }
                            } else {
                                PurchaseRow(purchase: purchase)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Purchases")
            .onAppear {
                fetchPurchases()
            }
        }
    }

    private var groupedPurchases: [String: [Purchase]] {
        Dictionary(grouping: purchases, by: { $0.tripName ?? "Unknown" })
    }

    private func fetchPurchases() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("User not logged in")
            return
        }

        let db = Firestore.firestore()

        db.collection("users").document(userID).collection("trips").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching trips: \(error.localizedDescription)")
                return
            }

            var purchasesList: [Purchase] = []

            let dispatchGroup = DispatchGroup()

            for document in querySnapshot!.documents {
                let tripCode = document.documentID

                dispatchGroup.enter()

                db.collection("users").document(userID).collection("trips").document(tripCode).collection("purchases").getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Error fetching purchases for trip \(tripCode): \(error.localizedDescription)")
                        dispatchGroup.leave()
                        return
                    }

                    for document in querySnapshot!.documents {
                        do {
                            var purchase = try document.data(as: Purchase.self)
                            purchasesList.append(purchase)
                        } catch {
                            print("Error decoding purchase: \(error.localizedDescription)")
                        }
                    }

                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.purchases = purchasesList.sorted(by: { $0.timestamp.seconds > $1.timestamp.seconds })
            }
        }
    }
}

struct PurchaseRow: View {
    var purchase: Purchase

    var body: some View {
        VStack(alignment: .leading) {
            Text(purchase.name)
                .font(.headline)
            Text("\(purchase.category) - $\(String(format: "%.2f", purchase.price)) - \(purchase.type)")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

struct PurchaseDetailView: View {
    var purchase: Purchase

    var body: some View {
        List {
            Section(header: Text("Shared With")) {
                if !purchase.sharedWith.isEmpty {
                    ForEach(purchase.sharedWith, id: \.self) { email in
                        Text(email)
                    }
                } else {
                    Text("No shared emails.")
                        .foregroundColor(.gray)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(purchase.name)
    }
}
