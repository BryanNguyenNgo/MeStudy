import SwiftUI

struct MenuView: View {
    @EnvironmentObject var userSession: UserSession
    @AppStorage("selectedtab")var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab){
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(1)
            CreateStudyPlanView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle")
                }
                .tag(2)
            StudyTipsView()
                .tabItem {
                    Label("Tips", systemImage: "plus.circle")
                }
                .tag(3)
            UserView(userSession: userSession)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(4)
        }
    }
}

#Preview {
    MenuView()
}

// Placeholder Views

