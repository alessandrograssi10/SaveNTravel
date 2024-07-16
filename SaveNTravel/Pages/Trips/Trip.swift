import SwiftUI
import FirebaseFirestore

struct Trip: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let description: String
    let code: String
    var timestamp: Timestamp
}

struct TripData: Codable {
    var destination: String
    var totalBudget: Double
    var categories: [Category]
    var timestamp: Timestamp
    var participants: [String]

}

struct Category: Codable, Identifiable {
    var id: String { name }
    var name: String
    var color: String
    var budget: Double
}
struct Participant: Identifiable {
    var id: String { email }
    var email: String
    var name: String
    var surname: String
}
