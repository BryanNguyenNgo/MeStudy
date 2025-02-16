import Foundation

class UserSession: ObservableObject {
    @Published var currentUser: User? = nil

    init() {
        loadFromSession()
    }
    
    func createUser(user: User) {
           self.currentUser = user// Update the user
       }
    func saveToSession(user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
        self.currentUser = user
    }

    func loadFromSession() {
        if let savedData = UserDefaults.standard.data(forKey: "currentUser"),
           let decodedUser = try? JSONDecoder().decode(User.self, from: savedData) {
            self.currentUser = decodedUser
        }
    }

    func clearSession() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
        self.currentUser = nil
    }
}

