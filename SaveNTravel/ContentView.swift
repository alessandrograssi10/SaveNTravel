import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Image("logo") // Assicurati di avere il tuo logo nell'asset catalog con il nome "logo"
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                
                Text("SaveNTravel")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                
                
                NavigationLink(destination: SignUpViewController()) {
                    Text("Sign Up")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                NavigationLink(destination: SignInViewController()) {
                    Text("Sign In")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
