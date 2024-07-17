import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct JoinGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var groupCode: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToAddTripView = false
    
    @State private var destination: String = ""
    @State private var totalBudget: String = ""
    @State private var showCategorySheet = false
    @State private var categories: [(name: String, color: Color, budget: Double)] = []
    @State private var newCategory: String = ""
    @State private var selectedColor: Color = .blue
    @State private var categoryBudget: String = ""
    @State private var selectedCategory: String?
    
    let popularCategories = ["Transport", "Food", "Accommodation", "Activities", "Miscellaneous"]
    let db = Firestore.firestore()
    
    var othersBudget: Double {
        let totalAllocated = categories.reduce(0) { $0 + $1.budget }
        return (Double(totalBudget) ?? 0) - totalAllocated
    }
    
    var body: some View {
        NavigationView {
            Form {
                if navigateToAddTripView {
                    Section(header: Text("Trip Details")) {
                        TextField("Destination", text: $destination)
                            .disabled(true) // make destination non-editable
                    }
                    
                    Section(header: Text("Total Budget")) {
                        TextField("Total Budget", text: $totalBudget)
                            .keyboardType(.decimalPad)
                    }
                    
                    Section(header: Text("Categories")) {
                        Text("You can manage your budget better by categorizing your expenses. You can also modify this later.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.bottom)
                        
                        ForEach(categories, id: \.name) { category in
                            HStack {
                                Text(category.name)
                                Spacer()
                                Text("\(category.budget, specifier: "%.2f")")
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        
                        if othersBudget > 0 {
                            HStack {
                                Text("Others")
                                Spacer()
                                Text("\(othersBudget, specifier: "%.2f")")
                                Circle()
                                    .fill(Color.purple)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        
                        Button(action: {
                            showCategorySheet.toggle()
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Category")
                            }
                        }
                    }
                    
                    Button(action: {
                        joinGroup()
                    }) {
                        Text("Join Group")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding()
                    }
                } else {
                    TextField("Enter Group Code", text: $groupCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 5)
                    Button(action: {
                        verifyGroup()
                    }) {
                        Text("Verify")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding()
                    }
                }
            }
            .navigationTitle(navigateToAddTripView ? "Manage Trip" : "Join Group")
            .sheet(isPresented: $showCategorySheet) {
                VStack {
                    Text("Add a new category")
                        .font(.headline)
                        .padding()
                    
                    ChipsMenu(selectedCategory: $selectedCategory, popularCategories: popularCategories, newCategory: $newCategory)
                    
                    if selectedCategory == "Custom" {
                        TextField("Category Name", text: $newCategory)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    }
                    
                    TextField("Category Budget", text: $categoryBudget)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    ColorPicker("Select Color", selection: $selectedColor)
                        .padding()
                    
                    Button(action: {
                        addCategory()
                    }) {
                        Text("Add")
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
        }
    }
    
    private func verifyGroup() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not logged in."
            showAlert = true
            return
        }
        
        db.collection("trips").document(groupCode.uppercased()).getDocument { (document, error) in
            if let document = document, document.exists {
                // Check if the user is already a member
                let users = document.get("users") as? [String] ?? []
                if users.contains(user.email ?? "") {
                    alertMessage = "You are already a member of this group."
                    showAlert = true
                    return
                }
                
                // Load trip details to manage
                destination = document.get("destination") as? String ?? ""
                totalBudget = String(document.get("totalBudget") as? Double ?? 0.0)
                if let fetchedCategories = document.get("categories") as? [[String: Any]] {
                    categories = fetchedCategories.map { category in
                        let name = category["name"] as? String ?? ""
                        let colorDesc = category["color"] as? String ?? ""
                        let color = Color(UIColor(hex: colorDesc))
                        let budget = category["budget"] as? Double ?? 0.0
                        return (name: name, color: color, budget: budget)
                    }
                }
                
                navigateToAddTripView = true
            } else {
                alertMessage = "Group code not found."
                showAlert = true
            }
        }
    }
    
    private func joinGroup() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not logged in."
            showAlert = true
            return
        }
        
        // Add user to the group's users array
        db.collection("trips").document(groupCode).updateData([
            "users": FieldValue.arrayUnion([user.email ?? ""])
        ]) { error in
            if let error = error {
                print("Error adding user to group: \(error.localizedDescription)")
                alertMessage = "Error adding user to group: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            // Save trip details under user's document
            var tripDetailData: [String: Any] = [
                "totalBudget": Double(totalBudget) ?? 0.0,
                "categories": categories.map { [
                    "name": $0.name,
                    "color": hexString(from: $0.color),
                    "budget": $0.budget
                ]}
            ]
            
            if var tripCategories = tripDetailData["categories"] as? [[String: Any]], othersBudget > 0 {
                let othersCategory: [String: Any] = [
                    "name": "Others",
                    "color": hexString(from: Color.purple),
                    "budget": othersBudget
                ]
                tripCategories.append(othersCategory)
                tripDetailData["categories"] = tripCategories
            }
            
            db.collection("users").document(user.uid).collection("trips").document(groupCode).setData(tripDetailData) { error in
                if let error = error {
                    print("Error saving trip details: \(error.localizedDescription)")
                    alertMessage = "Error saving trip details: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                // Add trip code to user's trips array
                db.collection("users").document(user.uid).updateData([
                    "trips": FieldValue.arrayUnion([groupCode])
                ]) { error in
                    if let error = error {
                        print("Error updating user's trips: \(error.localizedDescription)")
                        alertMessage = "Error updating user's trips: \(error.localizedDescription)"
                        showAlert = true
                        return
                    }
                    
                    // Send notification
                    NotificationCenter.default.post(name: NSNotification.Name("JoinGroupSuccess"), object: nil)
                    
                    // Close both views
                    print("Successfully joined group: \(groupCode)")
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func addCategory() {
        guard let budget = Double(categoryBudget), budget + categories.reduce(0, { $0 + $1.budget }) <= Double(totalBudget) ?? 0 else {
            alertMessage = "Invalid category budget or exceeds total budget."
            showAlert = true
            return
        }
        
        let categoryName = selectedCategory == "Custom" ? newCategory : selectedCategory ?? ""
        
        guard !categoryName.isEmpty else {
            alertMessage = "Category name cannot be empty."
            showAlert = true
            return
        }
        
        categories.append((name: categoryName, color: selectedColor, budget: budget))
        newCategory = ""
        categoryBudget = ""
        selectedColor = .blue
        selectedCategory = nil
        showCategorySheet = false
    }
}


private func hexString(from color: Color) -> String {
    let uiColor = UIColor(color)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    return String(format: "#%02lX%02lX%02lX%02lX",
                  lround(Double(r * 255)),
                  lround(Double(g * 255)),
                  lround(Double(b * 255)),
                  lround(Double(a * 255)))
}

extension UIColor {
    convenience init(hex: String) {
        var hexFormatted: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        hexFormatted = hexFormatted.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        let alpha = CGFloat(1.0)
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

struct JoinGroupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            JoinGroupView()
        }
    }
}
