import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var destination: String = ""
    @State private var totalBudget: String = ""
    @State private var showCategorySheet = false
    @State private var categories: [(name: String, color: Color, budget: Double)] = []
    @State private var newCategory: String = ""
    @State private var selectedColor: Color = Color(red: 0.929966, green: 0.452358, blue: 0.181053, opacity: 1) // Colore predefinito
    @State private var categoryBudget: String = ""
    @State private var selectedCategory: String?
    @State private var participants: [String] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showTripsView = false  // Stato per la navigazione
    
    let db = Firestore.firestore()
    
    var tripDetails: TripData?
    var tripCode: String
    
    var othersBudget: Double {
        let totalAllocated = categories.filter { $0.name != "Others" }.reduce(0) { $0 + $1.budget }
        return (Double(totalBudget) ?? 0) - totalAllocated
    }
    
    var body: some View {
        Form {
            Section(header: Text("Trip Details")) {
                TextField("Destination", text: $destination)
                    .disabled(true)
            }
            
            Section(header: Text("Total Budget")) {
                TextField("Total Budget", text: $totalBudget)
                    .keyboardType(.decimalPad)
            }
            
            Section(header: Text("Categories")) {
                ForEach(categories, id: \.name) { category in
                    HStack {
                        Text(category.name)
                        Spacer()
                        Text("\(category.budget, specifier: "%.2f")")
                        Circle()
                            .fill(category.color)
                            .frame(width: 20, height: 20)
                        if category.name != "Others" {
                            Button(action: {
                                removeCategory(category: category)
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle()) // Ensure button doesn't interfere with tap gesture
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if category.name != "Others" {
                            editCategory(category: category)
                        }
                    }
                }
                
                // Non aggiungere la categoria Others qui, la prenderemo solo dal database.
                
                Button(action: {
                    showCategorySheet.toggle()
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Category")
                    }
                }
            }
            
            
            Section {
                Button(action: deleteTrip) {
                    Text("Delete Trip")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Edit Trip")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Button("Save") {
                saveTrip()
            }
        )
        .sheet(isPresented: $showCategorySheet) {
            VStack {
                Text("Add/Edit a Category")
                    .font(.headline)
                    .padding()
                
                TextField("Category Name", text: $newCategory)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Category Budget", text: $categoryBudget)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                ColorPicker("Select Color", selection: $selectedColor)
                    .padding()
                
                Button(action: saveCategory) {
                    Text("Save")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            if let tripDetails = tripDetails {
                destination = tripDetails.destination
                totalBudget = "\(tripDetails.totalBudget)"
                categories = tripDetails.categories.map { (name: $0.name, color: Color.fromHex($0.color) ?? .gray, budget: $0.budget) }
                participants = tripDetails.participants
                
                // Non aggiungere la categoria Others qui, la prenderemo solo dal database.
            }
        }
        .background(
            NavigationLink(destination: TripsView(), isActive: $showTripsView) {
                EmptyView()
            }
        )
    }
    
    private func saveTrip() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not logged in."
            showAlert = true
            return
        }
        
        guard let totalBudget = Double(totalBudget), totalBudget > 0 else {
            alertMessage = "Please enter a valid total budget."
            showAlert = true
            return
        }
        
        // Aggiorna il budget di "Others"
        if let index = categories.firstIndex(where: { $0.name == "Others" }) {
            categories[index].budget = othersBudget
        }
        
        let tripDetailData: [String: Any] = [
            "destination": destination,
            "tripCode": tripCode,
            "users": participants,
            "totalBudget": totalBudget,
            "categories": categories.filter { $0.budget > 0 }.map { ["name": $0.name, "color": $0.color.toHex(), "budget": $0.budget] }
        ]
        
        db.collection("users").document(user.uid).collection("trips").document(tripCode).setData(tripDetailData) { error in
            if let error = error {
                alertMessage = "Error saving trip: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func saveCategory() {
        guard let budget = Double(categoryBudget), budget + categories.filter({ $0.name != "Others" }).reduce(0, { $0 + $1.budget }) <= Double(totalBudget) ?? 0 else {
            alertMessage = "Invalid category budget or exceeds total budget."
            showAlert = true
            return
        }
        
        if let index = categories.firstIndex(where: { $0.name == selectedCategory }) {
            categories[index] = (name: newCategory, color: selectedColor, budget: budget)
        } else {
            categories.append((name: newCategory, color: selectedColor, budget: budget))
        }
        
        newCategory = ""
        categoryBudget = ""
        selectedColor = Color(red: 0.929966, green: 0.452358, blue: 0.181053, opacity: 1) // Assicurarsi che il colore predefinito sia impostato correttamente
        selectedCategory = nil
        showCategorySheet = false
        
        // Aggiorna il budget di "Others"
        if let index = categories.firstIndex(where: { $0.name == "Others" }) {
            categories[index].budget = othersBudget
        }
    }
    
    private func removeCategory(category: (name: String, color: Color, budget: Double)) {
        categories.removeAll { $0.name == category.name }
        if let index = categories.firstIndex(where: { $0.name == "Others" }) {
            categories[index].budget = othersBudget
        }
    }
    
    private func editCategory(category: (name: String, color: Color, budget: Double)) {
        newCategory = category.name
        selectedColor = category.color
        categoryBudget = "\(category.budget)"
        selectedCategory = category.name
        showCategorySheet = true
    }
    
    private func deleteTrip() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not logged in."
            showAlert = true
            return
        }

        print("User ID: \(user.uid)")  // Debug print
        print("Trip Code: \(tripCode)")  // Debug print

        let userTripsRef = db.collection("users").document(user.uid).collection("trips").document(tripCode)
        let userDocRef = db.collection("users").document(user.uid)
        let tripDocRef = db.collection("trips").document(tripCode)

        // Primo step: eliminare il trip dalla collezione personale dell'utente
        userTripsRef.delete { error in
            if let error = error {
                alertMessage = "Error deleting trip: \(error.localizedDescription)"
                showAlert = true
                return
            }

            print("Deleted trip from user's collection")  // Debug print

            // Secondo step: rimuovere il codice del trip dall'array trips nel documento dell'utente
            userDocRef.updateData([
                "trips": FieldValue.arrayRemove([tripCode])
            ]) { error in
                if let error = error {
                    alertMessage = "Error removing trip code from user document: \(error.localizedDescription)"
                    showAlert = true
                    return
                }

                print("Removed trip code from user's document array")  // Debug print

                // Terzo step: rimuovere l'email dell'utente dall'array users nel documento del trip
                tripDocRef.getDocument { (document, error) in
                    if let error = error {
                        alertMessage = "Error getting trip document: \(error.localizedDescription)"
                        showAlert = true
                        return
                    }

                    guard let document = document, document.exists else {
                        alertMessage = "Trip document does not exist."
                        showAlert = true
                        print("Trip document does not exist")  // Debug print
                        return
                    }

                    print("Document data: \(String(describing: document.data()))")  // Debug print

                    var data = document.data()
                    var users = data?["users"] as? [String] ?? []

                    print("Current users array: \(users)")  // Debug print

                    // Rimuovi l'utente dall'array users
                    users.removeAll { $0 == user.email }

                    print("Updated users array after removal: \(users)")  // Debug print

                    // Aggiorna il documento del trip con il nuovo array users
                    tripDocRef.updateData([
                        "users": users
                    ]) { error in
                        if let error = error {
                            alertMessage = "Error removing user email from trip: \(error.localizedDescription)"
                            showAlert = true
                            return
                        }

                        print("Updated trip document with new users array")  // Debug print

                        // Controlla se ci sono altri utenti associati al trip
                        if users.isEmpty {
                            // Se non ci sono più utenti, elimina il trip
                            tripDocRef.delete { error in
                                if let error = error {
                                    alertMessage = "Error deleting trip code: \(error.localizedDescription)"
                                    showAlert = true
                                    return
                                }

                                print("Deleted trip document as no users are left")  // Debug print

                                // Dismiss the view after successful deletion
                                dismissTwoViews()

                            }
                        } else {
                            // Dismiss the view if there are still users left in the trip
                            print("Trip still has users, not deleting the document")  // Debug print
                            // Dismiss the view after successful deletion
                            dismissTwoViews()
                        }
                    }
                }
            }
        }
    }
    
    private func dismissTwoViews() {
        // Set the showTripsView to true to navigate to TripsView
        showTripsView = true
        // Dismiss the current and parent views
        presentationMode.wrappedValue.dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

extension Color {
    static func fromHex(_ hex: String) -> Color? {
        let r, g, b, a: Double
        let start = hex.hasPrefix("#") ? hex.index(hex.startIndex, offsetBy: 1) : hex.startIndex
        let hexColor = String(hex[start...])
        
        if hexColor.count == 8 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            
            if scanner.scanHexInt64(&hexNumber) {
                r = Double((hexNumber & 0xff000000) >> 24) / 255
                g = Double((hexNumber & 0x00ff0000) >> 16) / 255
                b = Double((hexNumber & 0x0000ff00) >> 8) / 255
                a = Double(hexNumber & 0x000000ff) / 255
                
                return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
            }
        }
        return nil
    }
}


struct EditTripView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditTripView(tripDetails: TripData(destination: "Paris", totalBudget: 2000.0, categories: [Category(name: "Food", color: "FF0000FF", budget: 500.0)], timestamp: Timestamp(date: Date()), participants: ["test@example.com"]), tripCode: "ABC123")
        }
    }
}
