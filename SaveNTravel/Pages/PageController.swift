import SwiftUI
import FirebaseFirestore
import FirebaseCore
import FirebaseAuth

struct PageController: View {
    @State private var selectedTab = 1
    @State private var showActionSheet = false
    @State private var showIndividualPurchasePopup = false
    @State private var showSplitPurchasePopup = false
    
    // Add an EnvironmentObject to access the AuthViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Content of the page
            Group {
                switch selectedTab {
                case 0:
                    FriendsView() // Add FriendsView here
                case 1:
                    TripsView() // Add TripsView here
                case 2:
                    PurchasesView() // Add FriendsView here

                case 3:
                    ProfilePageContent() // Show ProfilePageContent here
                default:
                    Text("Home Page Content")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Separator line
            Divider()
                .background(Color.black)
            
            // Bottom menu
            HStack {
                Button(action: {
                    selectedTab = 0
                }) {
                    Image("friend")
                        .resizable()
                        .frame(width: 30, height: 40)
                        .padding()
                        .foregroundColor(selectedTab == 0 ? .orange : .black)
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    selectedTab = 1
                }) {
                    Image("plane")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .padding()
                        .foregroundColor(selectedTab == 1 ? .orange : .black)
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    showActionSheet.toggle()
                }) {
                    Image("square")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .padding()
                        .foregroundColor(selectedTab == 9 ? .orange : .black)
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    selectedTab = 2
                }) {
                    Image("line-chart")
                        .resizable()
                        .frame(width: 27, height: 27)
                        .padding()
                        .foregroundColor(selectedTab == 2 ? .orange : .black)
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    selectedTab = 3
                }) {
                    VStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .padding()
                            .foregroundColor(selectedTab == 3 ? .orange : .black)
                        
                          
                            .cornerRadius(50)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 15)
            .background(Color(.white))
        }
        .edgesIgnoringSafeArea(.bottom)
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(title: Text("Select Option"), buttons: [
                .default(Text("INDIVIDUAL")) {
                    showIndividualPurchasePopup = true
                },
                .default(Text("SPLIT")) {
                    showSplitPurchasePopup = true
                },
                .cancel()
            ])
        }
        .sheet(isPresented: $showIndividualPurchasePopup) {
            IndividualPurchasePopup(showPopup: $showIndividualPurchasePopup)
                .environmentObject(PurchaseViewModel())
        }
        .sheet(isPresented: $showSplitPurchasePopup) {
            SplitPurchasePopup(showPopup: $showSplitPurchasePopup)
                .environmentObject(PurchaseViewModel())
        }
    }
}



struct PageController_Previews: PreviewProvider {
    static var previews: some View {
        PageController()
            .environmentObject(AuthViewModel()) // Provide a sample AuthViewModel instance
    }
}
