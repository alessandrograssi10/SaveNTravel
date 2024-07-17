import Foundation
import FirebaseFirestore


struct Purchase: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let category: String
    let price: Double
    let sharedWith: [String]
    let timestamp: Timestamp
    var tripName: String?
    var authoredBy: String
    var type: String

    var date: Date {
        return timestamp.dateValue()
    }
    
    init(name: String, category: String, price: Double, sharedWith: [String] = [], timestamp: Timestamp = Timestamp(date: Date()), tripName: String? = nil, authoredBy: String, type: String) {
        self.name = name
        self.category = category
        self.price = price
        self.sharedWith = sharedWith
        self.timestamp = timestamp
        self.tripName = tripName
        self.authoredBy = authoredBy
        self.type = type
    }
}
