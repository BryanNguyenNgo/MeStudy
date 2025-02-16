import SwiftUI

@main  // ✅ This tells Swift that this is the app's entry point
struct MeStudy: App {
    @StateObject private var userSession = UserSession()  // Initialize the user session
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            if let user = userSession.currentUser, user.name.isEmpty || user.email.isEmpty { // Check if user details are incomplete
                UserView(userSession: userSession)
            } else {
                TabView {
                    MenuView()
                        .environmentObject(userSession)  // Pass the userSession to MenuView
                }
                .onAppear {
                    Task {
                        await appViewModel.initializeDatabase()
                    }
                }
            }
        }
    }
}
