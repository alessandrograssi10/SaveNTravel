import SwiftUI
import FirebaseFirestore
import FirebaseCore
import FirebaseAuth

struct IndividualPurchasePopup: View {
    @Binding var showPopup: Bool
    @State private var nomeSpesa: String = ""
    @State private var category: String = ""
    @State private var amount: String = ""
    @State private var categories: [Category] = [] // Categories for the selected trip
    @State private var userTrips: [Trip] = []
    @State private var selectedTrip: Trip? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var userID: String? = nil
    @State private var userEmail: String? = nil
    @State private var tripCategories: [Category] = [] // Variabile per le categorie del trip selezionato
    @State private var selectedCategory: Category? = nil // Variabile per la categoria selezionata
    @State private var showTripPicker = false // Stato per visualizzare il menu a tendina dei viaggi

    @EnvironmentObject var purchaseViewModel: PurchaseViewModel

    let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                HStack {
                    Button(action: {
                        showPopup = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                            .padding()
                    }
                    Spacer()
                }
                .padding(.top)

                Text("INDIVIDUAL PURCHASE")
                    .font(.headline)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()

                TextField("Enter title of expense", text: $nomeSpesa)
                    .font(.title2)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.vertical)

                Text("SELECT TRIP")
                    .font(.caption)
                    .bold()
                    .padding(.leading)

                Menu {
                    ForEach(userTrips) { trip in
                        Button(action: {
                            selectedTrip = trip
                            fetchCategories(for: trip)
                        }) {
                            Text(trip.title)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedTrip?.title ?? "Select a trip")
                            .foregroundColor(selectedTrip == nil ? .gray : .black)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.vertical)

                Text("CATEGORY")
                    .font(.caption)
                    .bold()
                    .padding(.leading)

                if !tripCategories.isEmpty {
                    VStack {
                        ForEach(tripCategories) { category in
                            RadioButtonField(id: category.id, label: category.name, isMarked: selectedCategory?.id == category.id) { selectedId in
                                if let selectedCat = tripCategories.first(where: { $0.id == selectedId }) {
                                    selectedCategory = selectedCat
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    Text(" ")
                    Text("You must select a trip")
                        .padding(.leading)
                        .font(.system(size: 18))
                }

                Text("INSERT AMOUNT")
                    .font(.caption)
                    .bold()
                    .padding(.leading)
                    .padding(.top)
                    .padding(.vertical)

                TextField("Enter amount", text: $amount)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                Spacer()

                Button(action: {
                                    if let userID = userID, let userEmail = userEmail, let trip = selectedTrip, let category = selectedCategory, let price = Double(amount) {
                                        let newPurchase = Purchase(name: nomeSpesa, category: category.name, price: price, sharedWith: [], timestamp: Timestamp(date: Date()), tripName: trip.title, authoredBy: userEmail)
                                        purchaseViewModel.addPurchase(newPurchase, userID: userID, tripCode: trip.code)
                                        showPopup = false
                                    }
                                }) {
                                    Text("Done")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                                .padding()
                            }
                            .onAppear {
                                fetchUserTrips()
                                fetchUserEmail() // Ottieni l'email dell'utente quando la vista appare
                            }
                        }
                    }

    struct RadioButtonField: View {
        let id: String
        let label: String
        let isMarked: Bool
        let callback: (String) -> ()

        var body: some View {
            Button(action: {
                self.callback(self.id)
            }) {
                HStack {
                    Text(self.label)
                        .font(.body)
                        .bold()
                    Spacer()
                    if self.isMarked {
                        Image(systemName: "largecircle.fill.circle")
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(35)
            }
        }
    }

    private func fetchUserTrips() {
            guard let user = Auth.auth().currentUser else {
                alertMessage = "User not logged in."
                showAlert = true
                return
            }

            userID = user.uid

            db.collection("users").document(user.uid).getDocument { (document, error) in
                if let document = document, document.exists {
                    let data = document.data()
                    if let tripCodes = data?["trips"] as? [String] {
                        fetchTrips(tripCodes: tripCodes)
                    }
                } else {
                    alertMessage = "Error fetching user data: \(error?.localizedDescription ?? "Unknown error")"
                    showAlert = true
                }
            }
        }

        private func fetchUserEmail() {
            guard let user = Auth.auth().currentUser else {
                alertMessage = "User not logged in."
                showAlert = true
                return
            }

            userEmail = user.email // Ottieni l'email dell'utente autenticato
        }

        private func fetchTrips(tripCodes: [String]) {
            let dispatchGroup = DispatchGroup()
            var fetchedTrips: [Trip] = []

            for tripCode in tripCodes {
                dispatchGroup.enter()
                db.collection("trips").document(tripCode).getDocument { (document, error) in
                    defer { dispatchGroup.leave() }

                    if let document = document, document.exists {
                        if let data = document.data(),
                           let destination = data["destination"] as? String,
                           let timestamp = data["timestamp"] as? Timestamp {
                            let trip = Trip(
                                imageName: data["imageName"] as? String ?? "defaultImage",
                                title: destination,
                                description: data["description"] as? String ?? "This is a trip description",
                                code: tripCode,
                                timestamp: timestamp
                            )
                            fetchedTrips.append(trip)
                        } else {
                            print("Error: Missing required trip fields for trip code \(tripCode)")
                        }
                    } else {
                        alertMessage = "Error fetching trip data: \(error?.localizedDescription ?? "Unknown error")"
                        showAlert = true
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.userTrips = fetchedTrips // Aggiornamento della lista dei trips dell'utente
            }
        }

        private func fetchCategories(for trip: Trip) {
            guard let user = Auth.auth().currentUser else {
                alertMessage = "User not logged in."
                showAlert = true
                return
            }

            userID = user.uid

            // Accedi alla collezione "trips" all'interno del documento utente
            db.collection("users").document(user.uid).collection("trips").document(trip.code).getDocument { (document, error) in
                if let document = document, document.exists {
                    do {
                        // Prova a decodificare il campo "categories" come un array di oggetti Category
                        if let categoriesData = document.data()?["categories"] as? [[String: Any]] {
                            // Decodifica manuale dell'array di categorie
                            var decodedCategories: [Category] = []
                            for categoryData in categoriesData {
                                if let jsonData = try? JSONSerialization.data(withJSONObject: categoryData),
                                   let category = try? JSONDecoder().decode(Category.self, from: jsonData) {
                                    decodedCategories.append(category)
                                }
                            }
                            // Assegna le categorie decodificate alla variabile di stato tripCategories
                            tripCategories = decodedCategories
                        } else {
                            alertMessage = "Categories data is not in the expected format."
                            showAlert = true
                        }
                    } catch {
                        alertMessage = "Error decoding trip data: \(error.localizedDescription)"
                        showAlert = true
                    }
                } else {
                    alertMessage = "Error fetching trip data: \(error?.localizedDescription ?? "Unknown error")"
                    showAlert = true
                }
            }
        }
    }
