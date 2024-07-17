import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AddTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var destination: String = ""
    @State private var totalBudget: String = ""
    @State private var showCategorySheet = false
    @State private var categories: [(name: String, color: Color, budget: Double)] = []
    @State private var newCategory: String = ""
    @State private var selectedColor: Color = .red
    @State private var categoryBudget: String = ""
    @State private var selectedCategory: String? = nil
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let popularCategories = ["Transport", "Food", "Accommodation", "Activities", "Miscellaneous"]
    let db = Firestore.firestore()
    
    var othersBudget: Double {
        let totalAllocated = categories.reduce(0) { $0 + $1.budget }
        return (Double(totalBudget) ?? 0) - totalAllocated
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Destination", text: $destination)
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
                            editCategory(category: category)
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
            }
            .navigationTitle("Add Trip")
            .navigationBarItems(trailing: Button("Create") {
                createTrip()
            })
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
                        .onChange(of: selectedColor) { newColor in
                            if newColor == .blue {
                                selectedColor = .red
                                alertMessage = "Blue color is reserved for the total budget."
                                showAlert = true
                            }
                        }
                    
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
    
    private func generateRandomCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<5).map { _ in letters.randomElement()! })
    }
    
    private func createTrip() {
        guard let user = Auth.auth().currentUser else {
            alertMessage = "User not logged in."
            showAlert = true
            return
        }
        
        guard !destination.isEmpty else {
            alertMessage = "Destination name cannot be empty."
            showAlert = true
            return
        }
        
        guard let totalBudget = Double(totalBudget), totalBudget > 0 else {
            alertMessage = "Please enter a valid total budget."
            showAlert = true
            return
        }
        
        let tripCode = generateRandomCode()
        let timestamp = Timestamp(date: Date())
        
        let tripData: [String: Any] = [
            "destination": destination,
            "tripCode": tripCode,
            "users": [user.email ?? ""],
            "timestamp": timestamp,
            "description": "This is a trip description",
            "imageName": "defaultImage"
        ]
        
        var tripDetailData: [String: Any] = [
            "totalBudget": totalBudget,
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
        
        db.collection("trips").document(tripCode).setData(tripData) { error in
            if let error = error {
                print("Error adding trip: \(error.localizedDescription)")
                alertMessage = "Error adding trip: \(error.localizedDescription)"
                showAlert = true
                return
            }
            
            db.collection("users").document(user.uid).collection("trips").document(tripCode).setData(tripDetailData) { error in
                if let error = error {
                    print("Error saving trip details: \(error.localizedDescription)")
                    alertMessage = "Error saving trip details: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                db.collection("users").document(user.uid).updateData([
                    "trips": FieldValue.arrayUnion([tripCode])
                ]) { error in
                    if let error = error {
                        print("Error updating user's trips: \(error.localizedDescription)")
                        alertMessage = "Error updating user's trips: \(error.localizedDescription)"
                        showAlert = true
                        return
                    }
                    
                    print("Trip successfully created: \(tripCode)")
                    presentationMode.wrappedValue.dismiss() // Chiudere la vista una volta creato il viaggio
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
        selectedColor = .red
        selectedCategory = nil
        showCategorySheet = false
    }
    
    private func removeCategory(category: (name: String, color: Color, budget: Double)) {
        categories.removeAll { $0.name == category.name }
    }
    
    private func editCategory(category: (name: String, color: Color, budget: Double)) {
        newCategory = category.name
        selectedColor = category.color
        categoryBudget = "\(category.budget)"
        selectedCategory = category.name
        showCategorySheet = true
    }
}

struct ChipsMenu: View {
    @Binding var selectedCategory: String?
    let popularCategories: [String]
    @Binding var newCategory: String
    let spacing: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            FlexibleView(
                availableWidth: geometry.size.width,
                data: popularCategories + ["Custom"],
                spacing: spacing,
                alignment: .leading
            ) { category in
                Button(action: {
                    if category == "Custom" {
                        selectedCategory = "Custom"
                    } else {
                        selectedCategory = category
                        newCategory = ""
                    }
                }) {
                    Text(category)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedCategory == category ? .white : .black)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .frame(minHeight: 0, maxHeight: 115)
    }
}

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    @State var elementsSize: [Data.Element: CGSize] = [:]

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { rowElements in
                HStack(spacing: spacing) {
                    ForEach(rowElements, id: \.self) { element in
                        content(element)
                            .fixedSize()
                            .readSize { size in
                                elementsSize[element] = size
                            }
                    }
                }
            }
        }
    }

    private func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth

        for element in data {
            let elementSize = elementsSize[element, default: CGSize(width: availableWidth, height: 1)]

            if remainingWidth - (elementSize.width + spacing) >= 0 {
                rows[currentRow].append(element)
                remainingWidth -= (elementSize.width + spacing)
            } else {
                currentRow += 1
                rows.append([element])
                remainingWidth = availableWidth - (elementSize.width + spacing)
            }
        }

        return rows
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}


extension Color {
    func toHex() -> String {
        let components = self.cgColor?.components ?? [0, 0, 0, 1]
        let r = components[0]
        let g = components.count > 1 ? components[1] : r
        let b = components.count > 2 ? components[2] : r
        let a = components.count > 3 ? components[3] : 1.0
        return String(format: "#%02lX%02lX%02lX%02lX",
                      lround(Double(r * 255)),
                      lround(Double(g * 255)),
                      lround(Double(b * 255)),
                      lround(Double(a * 255)))
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

struct AddTripView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddTripView()
        }
    }
}
