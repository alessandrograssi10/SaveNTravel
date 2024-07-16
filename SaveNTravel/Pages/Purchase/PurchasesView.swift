import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PurchasesView: View {
    @EnvironmentObject var purchaseViewModel: PurchaseViewModel
    //var userID: String
    @State private var purchases: [Purchase] = []    //var tripCode: String
    
    
    var body: some View {
        NavigationView {
            List {
                ForEach(purchases.sorted(by: { $0.timestamp.seconds > $1.timestamp.seconds })) { purchase in
                    VStack(alignment: .leading) {
                        Text("\(purchase.name)")
                            .font(.headline)
                        Text("\(purchase.category) - $\(String(format: "%.2f", purchase.price))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Purchases")
            .onAppear {
                fetchPurchases()
            }
        }
    }
    
    
    
    
    private func fetchPurchases() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Utente non ha effettuato l'accesso")
            return
        }
        
        let db = Firestore.firestore()
        
        // Esempio di query per recuperare gli acquisti dell'utente
        db.collection("users").document(userID).collection("trips").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Errore nel recupero degli acquisti: \(error.localizedDescription)")
                return
            }
            
            var purchasesList: [Purchase] = []
            
            for document in querySnapshot!.documents {
                let tripCode = document.documentID
                
                // Recupera gli acquisti per ogni tripCode
                db.collection("users").document(userID).collection("trips").document(tripCode).collection("purchases").getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Errore nel recupero degli acquisti per il trip \(tripCode): \(error.localizedDescription)")
                        return
                    }
                    
                    for document in querySnapshot!.documents {
                        do {
                            // Prova a decodificare il documento in un oggetto Purchase
                            let purchase = try document.data(as: Purchase.self)
                            purchasesList.append(purchase)
                        } catch {
                            print("Errore durante la decodifica dell'acquisto: \(error.localizedDescription)")
                        }
                    }
                    
                    
                    self.purchases = purchasesList.sorted(by: { $0.timestamp.seconds > $1.timestamp.seconds })
                }
            }
        }
    }
}
