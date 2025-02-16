
import Foundation
// Mark the method with @MainActor to ensure that the method runs on the main thread, including access to @Published properties.
@MainActor
class AppViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    
    // Initialize Database (called from App entry point)
    func initializeDatabase() async {
        await DatabaseManager.shared.initializeDatabase()
        
        // Now this will be executed on the main thread since the class is marked with @MainActor
        self.isLoading = false
    }
}
