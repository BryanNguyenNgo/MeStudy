import SwiftUI

struct HomeView: View {
    @StateObject private var userSession = UserSession()
    @State private var showingCreateUserView = false
    @State private var isLoggedOut = false  // State to manage the logout action
    @AppStorage("selectedtab")var selectedTab = 0
    var body: some View {
        
        NavigationView {
            VStack(spacing: 20) {
                if let user = userSession.currentUser {
                    // Show the Home content if the user exists
                    // Other home content
                } else {
                    // Show a prompt to create the user profile
                    Button("Create User Profile") {
                        showingCreateUserView.toggle()
                    }
                    .sheet(isPresented: $showingCreateUserView) {
                        UserView(userSession: userSession)  // Pass the session to UserView
                    }
                }
                
                // Welcome Message (moved inside the condition)
                if let user = userSession.currentUser {
                    Text("Welcome back, \(user.name)!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                }
                
                Text("What would you like to do today?")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                // Navigation Buttons
                HStack {
                    NavigationLink(destination: CreateStudyPlanView()) {
                        HomeButton(icon: "plus.circle.fill", label: "Create")
                    }
                    NavigationLink(destination: LibraryView(), isActive: Binding(
                                       get: { selectedTab == 3 },
                                       set: { if $0 { selectedTab = 3 } }
                                   )) {
                                       HomeButton(icon: "books.vertical", label: "Library")
                                   }
                    NavigationLink(destination: StudyTipsView()) {
                        HomeButton(icon: "lightbulb.fill", label: "Study Tips")
                    }
                }
                
                // Recent Study Plans (Placeholder)
                Text("Recent Study Plans")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                

                    VStack(alignment: .leading) {
                        Text("📘 Math - 2 hours daily")
                        Text("📗 Science - 1.5 hours weekly")
                        Text("📙 History - 1 hour weekly")
                    }
                    .padding()

                
                // Study Tips Section
                Text("Study Tips")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                

                    VStack(alignment: .leading) {
                        Text("📚 Break study into smaller, manageable sessions.")
                        Text("💡 Take regular breaks to keep your mind fresh.")
                        Text("📝 Use active recall and spaced repetition.")
                        Text("🌟 Stay organized and plan ahead.")
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                // Check if the user already exists in session
                if userSession.currentUser == nil {
                    showingCreateUserView = true
                }
            }
            .navigationBarTitle("Home", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                // Clear the session and log the user out
                userSession.clearSession()
                isLoggedOut = true
                // Optionally, navigate to a login screen here
            }) {
                Text("Logout")
                    .font(.headline)
                    .foregroundColor(.blue)
            })
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
