import SwiftUI

struct MenuView: View {
    @EnvironmentObject var userSession: UserSession
    @AppStorage("selectedtab") var selectedTab = 0

    @StateObject private var userViewModel = UserViewModel() // Initialize `UserViewModel`

    var body: some View {
        TabView(selection: $selectedTab) {
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
            
            UserView(viewModel: userViewModel) // Pass the `viewModel` to `UserView`
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(4)
        }
        .environmentObject(userSession) // Pass userSession to UserView
    }
}

#Preview {
    // Mock UserSession for Preview
    MenuView().environmentObject(UserSession())
}
