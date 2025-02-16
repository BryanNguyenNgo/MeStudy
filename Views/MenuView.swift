import SwiftUI

struct MenuView: View {
    @EnvironmentObject var userSession: UserSession
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            StudyPlanView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle")
                }
            StudyTipsView()
                .tabItem {
                    Label("Tips", systemImage: "plus.circle")
                }
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
            UserView(userSession: userSession)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

#Preview {
    MenuView()
}

// Placeholder Views

