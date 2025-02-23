import Foundation

final class User: Identifiable, ObservableObject, Equatable, Codable {
    let id: String
    var name: String
    var email: String
    var grade: String
    
    static let shared = User(id: "", name: "", email:"", grade:"")
    
    init(id: String, name: String, email: String, grade: String) {
        self.id = id
        self.name = name
        self.email = email
        self.grade = grade
    }
    
    // Ensure `Equatable` conformance
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    
    
    // Save user to database (Async)
    func saveToDatabase() async throws -> User {
        do {
            // Directly assign the result since it is non-optional
            let insertedUser = try await DatabaseManager.shared.insertUser(id: self.id, name: self.name, email: self.email, grade: self.grade)
            
            return insertedUser
        } catch {
            print("Database error: \(error.localizedDescription)")
            throw error
        }
    }
    func getUserByUserName(name: String) async -> Result<User, NSError> {
        do {
            if let user = try await DatabaseManager.shared.getUserByUserName(name: name) {
                return .success(user) // Wrap the user in Result.success
            } else {
                return .failure(NSError(domain: "DatabaseError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"]))
            }
        } catch let error as NSError {
            print("Database error: \(error.localizedDescription)")
            return .failure(error) // Return error wrapped in Result.failure
        }
    }


}
