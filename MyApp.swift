import SwiftUI

@main
struct MeStudy: App {

    // Initialize userSession and userViewModel correctly
    @StateObject private var userSession = UserSession()
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @AppStorage("selectedtab") var selectedTab = 0
    @AppStorage("offlineMode") private var offlineMode: Bool = true
    
    // Initialize userViewModel with userSession
    init() {
        // Perform any initialization if needed
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                MenuView()
                    .environmentObject(userSession)
            }
            .onAppear {
                Task {
                    do {
                        // Load offline mode
                        let offlineMode = await AppConfig.shared.loadOfflineMode()
                        var userFound: Bool = false
                        
                        // Ensure database is initialized
                        await appViewModel.initializeDatabase()

                        // Check if a user already exists in the database
                        let result = try await userViewModel.getUserByUserName(name: "usertest")

                        switch result {
                        case .success(let existingUser):
                            // If user exists, set it to the session
                            DispatchQueue.main.async {
                                userSession.currentUser = existingUser
                                userFound = true
                            }
                        case .failure(let error):
                            // Handle failure case (user not found or any other issue)
                            print("Error: \(error.localizedDescription)")
                            // Optionally, show an alert to the user
                            userFound = false
                        }
                        
                        // If no user found, insert a default user
                        if userSession.currentUser == nil || userFound == false {
                            let defaultUser = User(id: UUID().uuidString, name: "usertest", email: "usertest@gmail.com", grade: "10")

                            do {
                                let insertedUser = try await defaultUser.saveToDatabase()

                                DispatchQueue.main.async {
                                    userSession.currentUser = insertedUser
                                    selectedTab = 0
                                }
                            } catch {
                                print("Error saving default user to database: \(error)")
                            }
                        }

                    } catch {
                        print("Error during initialization: \(error)")
                    }
                }
            }
            .onDisappear {
                // Clear session when app closes
                userSession.currentUser = nil
            }
        }
    }
}
