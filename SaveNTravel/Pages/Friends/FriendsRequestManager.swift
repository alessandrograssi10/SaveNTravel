import FirebaseFirestore
import FirebaseAuth

class FriendRequestManager: ObservableObject {
    private let db = Firestore.firestore()
    
    func sendFriendRequest(from currentUserEmail: String, to userEmail: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard userEmail.lowercased() != currentUserEmail.lowercased() else {
            completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Cannot send friend request to yourself."])))
            return
        }
        
        let friendRequestData: [String: Any] = [
            "from": currentUserEmail,
            "to": userEmail,
            "status": "pending"
        ]
        
        db.collection("friendRequests")
            .whereField("from", isEqualTo: currentUserEmail)
            .whereField("to", isEqualTo: userEmail)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = querySnapshot?.documents, documents.isEmpty else {
                    completion(.failure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Friend request already sent."])))
                    return
                }
                
                self.db.collection("friendRequests")
                    .addDocument(data: friendRequestData) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
            }
    }
    
    func checkFriendRequestExists(from currentUserEmail: String, to userEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
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
                    if status == "pending" {
                        completion(.success("request sent")) // Richiesta di amicizia già inviata
                    } else if status == "accepted" {
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
                    if status == "pending" {
                        completion(.success("request received")) // Richiesta di amicizia ricevuta
                    } else if status == "accepted" {
                        completion(.success("already friend")) // Già amici
                    } else {
                        completion(.success("add")) // Nessuna richiesta di amicizia trovata
                    }
                } else {
                    completion(.success("add")) // Nessuna richiesta di amicizia trovata
                }
            }
    }


}
