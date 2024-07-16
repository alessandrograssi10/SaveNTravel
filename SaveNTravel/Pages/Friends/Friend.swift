import SwiftUI

enum FriendRequestType {
    case sent
    case received
    case established
}

struct Friend: Identifiable {
    var id = UUID()
    var name: String
    var surname: String
    var email: String
    var pending: Bool
    var requestType: FriendRequestType
    
}

