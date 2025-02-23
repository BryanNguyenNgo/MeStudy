import SwiftUI

struct HomeView: View {
    @StateObject private var userSession = UserSession()
    @State private var showingCreateUserView = false
    @State private var isLoggedOut = false  // State to manage the logout action
    @AppStorage("selectedtab")var selectedTab = 0
    @AppStorage("offlineMode") private var offlineMode: Bool = false
    var body: some View {
        
        NavigationView {
            VStack(spacing: 20) {
                
                // Welcome Message (moved inside the condition)
                if let user = userSession.currentUser {
                    Text("Greetings, \(user.name)!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                }
                
                Text("What would you like to do today?")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                // Navigation Buttons
                HStack {
                    Button(action: { selectedTab = 2 }) {
                        HomeButton(icon: "plus.circle.fill", label: "Create")
                    }
                    Button(action: { selectedTab = 1 }) {
                        HomeButton(icon: "books.vertical", label: "Library")
                    }
                    Button(action: { selectedTab = 3 }) {
                        HomeButton(icon: "lightbulb.fill", label: "Study Tips")
                    }
                }
                
                // Recent Study Plans (Placeholder)

                RecentStudyPlanView()
                // Display app in offline mode
                Toggle("Offline Mode", isOn: $offlineMode)
                                .padding()
                Text("Offline Mode is \(offlineMode ? "Enabled" : "Disabled")")
                               .padding()

            }
            .padding()
            .onAppear {
                // Check if the user already exists in session
                if userSession.currentUser == nil {
                    showingCreateUserView = true
                }
            }
            .navigationBarTitle("Home", displayMode: .inline)
//            .navigationBarItems(trailing: Button(action: {
//                // Clear the session and log the user out
//                userSession.clearSession()
//                isLoggedOut = true
//                // Optionally, navigate to a login screen here
//            }) {
//                Text("Logout")
//                    .font(.headline)
//                    .foregroundColor(.blue)
//            })
        }
        
    }
    init() {
        UserDefaults.standard.set(0, forKey: "selectedTab")  // Reset to Home
    }
    
}

// Custom Button View
struct HomeButton: View {
    var icon: String
    var label: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
            Text(label)
                .font(.headline)
        }
        .frame(width: 100, height: 100)
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .shadow(radius: 3)
    }
}

// Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(UserSession())
    }
}
