import FirebaseFirestore

struct User: Identifiable {
    var id: String
    var name: String
    var surname: String
    var email: String
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let name = data["Name"] as? String,
              let surname = data["Surname"] as? String,
              let email = data["email"] as? String else {
            return nil
        }
        self.id = document.documentID
        self.name = name
        self.surname = surname
        self.email = email
    }
}


