import Foundation
import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

class PurchaseViewModel: ObservableObject {
    @Published var purchases: [String: [Purchase]] = [:] // Dictionary to store purchases by userID
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?


    
    
    func addPurchase(_ purchase: Purchase, userID: String, tripCode: String) {
            // Esegui l'aggiunta dell'acquisto nel database Firebase
            do {
                _ = try db.collection("users").document(userID)
                    .collection("trips").document(tripCode)
                    .collection("purchases").addDocument(from: purchase)
            } catch {
                print("Error adding purchase: \(error.localizedDescription)")
            }
        }
        
       
}



