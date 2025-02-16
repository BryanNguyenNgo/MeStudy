import Foundation

final class User: Identifiable, ObservableObject, Equatable, Codable {
    let id: String
    var name: String
    var email: String
    var grade: String
    
    init(name: String, email: String, grade: String) {
        self.id = UUID().uuidString
        self.name = name
        self.email = email
        self.grade = grade
    }
    
    // Ensure `Equatable` conformance
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    
    // Save user to database (Async)
    func saveToDatabase() async throws -> String {
        do {
            // Directly assign the result since it is non-optional
            let insertedUserId = try await DatabaseManager.shared.insertUser(id: self.id, name: self.name, email: self.email, grade: self.grade)
            
            return insertedUserId
        } catch {
            print("Database error: \(error.localizedDescription)")
            throw error
        }
    }


    
    
}
