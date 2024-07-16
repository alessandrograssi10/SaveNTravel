import SwiftUI
import FirebaseFirestore

struct TripView: View {
    var trip: Trip
    var isLarge: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) { // Align content to the top leading corner
                Image("dubai")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: isLarge ? 150 : 75) // Image height
                    .clipped()
                    .overlay(
                        Color.black.opacity(0.3)
                    )
                    .blur(radius: 1)
                
                Text(trip.title)
                    .font(isLarge ? .title : .headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding([.top, .leading])
            }
            .background(Color.white)
            
            // New black rectangle with code and share icon
            HStack {
                Text(trip.code)
                    .foregroundColor(.white)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: {
                    // Add action for sharing code here
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .frame(height: 50)
            .background(Color.black)
        }
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

struct TripView_Previews: PreviewProvider {
    static var previews: some View {
        TripView(trip: Trip(imageName: "dubai", title: "Trip to Dubai", description: "A wonderful trip to Dubai", code: "DUB123", timestamp: Timestamp()))
    }
}
