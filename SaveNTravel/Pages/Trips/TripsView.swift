import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TripsView: View {
    @State private var showAddTripView = false
    @State private var showJoinGroupView = false
    @State private var userTrips: [Trip] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToTrip: String? = nil
    @State private var userID: String? = nil
    
    let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack {
                if userTrips.isEmpty {
                    Text("No trips yet")
                        .font(.title)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(userTrips) { trip in
                                NavigationLink(value: trip.code) {
                                    TripView(trip: trip, isLarge: true)
                                }
                            }
                        }
                        .padding()
                        .onAppear(perform: fetchUserTrips)
                    }
                }
            }
            .navigationTitle("Trips")
            .navigationDestination(for: String.self) { tripCode in
                TripDetailView(tripCode: tripCode)
            }
            .navigationBarItems(trailing:
                Menu {
                    Button(action: {
                        showAddTripView = true
                    }) {
                        Text("Create Trip")
                        Image(systemName: "plus")
                    }
                    Button(action: {
                        showJoinGroupView = true
                    }) {
                        Text("Join Group with Code")
                        Image(systemName: "person.2.fill")
                    }
                } label: {
                    HStack {
                        //Text("Add trip")
                        Image(systemName: "plus")
                            .imageScale(.large)
                    }
                }

            )
            .fullScreenCover(isPresented: $showAddTripView, onDismiss: {
                fetchUserTrips()
            }) {
                NavigationView {
                    AddTripView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    showAddTripView = false
                                }
                            }
                        }
                }
                .transition(.move(edge: .bottom))
            }
            .fullScreenCover(isPresented: $showJoinGroupView, onDismiss: {
                fetchUserTrips()
            }) {
                NavigationView {
                    JoinGroupView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    showJoinGroupView = false
                                }
                            }
                        }
                }
                .transition(.move(edge: .bottom))
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .onAppear {
            fetchUserTrips()
            NotificationCenter.default.addObserver(forName: NSNotification.Name("JoinGroupSuccess"), object: nil, queue: .main) { _ in
                fetchUserTrips()
            }
        }
    }
    
    private func fetchUserTrips() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not logged in."
            showAlert = true
            print(alertMessage)
            return
        }
        
        userID = user.uid
        
        db.collection("users").document(user.uid).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let tripCodes = data?["trips"] as? [String] {
                    print("Fetched trip codes: \(tripCodes)")
                    fetchTrips(tripCodes: tripCodes) // Fetch trip details for these trip codes
                } else {
                    alertMessage = "No trips found for user."
                    showAlert = true
                    print(alertMessage)
                }
            } else {
                alertMessage = "Error fetching user data: \(error?.localizedDescription ?? "Unknown error")"
                showAlert = true
                print(alertMessage)
            }
        }
    }
    
    private func fetchTrips(tripCodes: [String]) {
        let dispatchGroup = DispatchGroup()
        var fetchedTrips: [Trip] = []
        
        for tripCode in tripCodes {
            dispatchGroup.enter()
            
            db.collection("trips").document(tripCode).getDocument { (tripDocument, error) in
                if let tripDocument = tripDocument, tripDocument.exists, let tripData = tripDocument.data() {
                    if let destination = tripData["destination"] as? String {
                        // Fetch detailed data from user's trip collection
                        self.db.collection("users").document(self.userID!).collection("trips").document(tripCode).getDocument { (document, error) in
                            if let document = document, document.exists {
                                let data = document.data()
                                let timestamp = data?["timestamp"] as? Timestamp ?? Timestamp(date: Date())
                                let description = data?["description"] as? String ?? "No description available"
                                let imageName = data?["imageName"] as? String ?? "defaultImage"
                                let totalBudget = data?["totalBudget"] as? Double ?? 0.0
                                let categories = data?["categories"] as? [[String: Any]] ?? []
                                
                                let trip = Trip(
                                    imageName: imageName,
                                    title: destination,
                                    description: description,
                                    code: tripCode,
                                    timestamp: timestamp
                                )
                                fetchedTrips.append(trip)
                                print("Fetched trip: \(trip)")
                                dispatchGroup.leave()
                            } else {
                                self.alertMessage = "Error fetching trip data for code \(tripCode): \(error?.localizedDescription ?? "Unknown error")"
                                self.showAlert = true
                                print(self.alertMessage)
                                dispatchGroup.leave()
                            }
                        }
                    } else {
                        print("Error: Missing destination for trip code \(tripCode)")
                        dispatchGroup.leave()
                    }
                } else {
                    print("Error: Trip document not found for trip code \(tripCode)")
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.userTrips = fetchedTrips.sorted(by: { $0.timestamp.dateValue() > $1.timestamp.dateValue() }) // Sort trips by timestamp
            print("User trips: \(self.userTrips)")
        }
    }
}

struct TripsView_Previews: PreviewProvider {
    static var previews: some View {
        TripsView()
    }
}
