import Foundation
import SwiftUI

class UserViewModel: ObservableObject {
    @EnvironmentObject var userSession: UserSession
    
    @Published var selectedGrade: String? = nil  // Make this optional
    
    // For UI display
    @Published var grades: [String] = []
    
    // Load data from JSON for grades, subjects, and topics
    func loadDataSubjectTopics() async {
        // Load JSON data from a file
        if let url = Bundle.main.url(forResource: "Data_SubjectTopics", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            let decoder = JSONDecoder()
            if let decodedData = try? decoder.decode([GradeData].self, from: data) {
                grades = decodedData.map { "Grade \($0.grade)" }
                
//                // Populate subjects and topics
//                for gradeData in decodedData {
//                    let gradeKey = "Grade \(gradeData.grade)"
//                    subjects[gradeKey] = gradeData.subjects.map { $0.subject }
//                    for subject in gradeData.subjects {
//                        topics["\(gradeKey)-\(subject.subject)"] = subject.topics
//                    }
//                }
            }
        }
    }
    
    // Select a grade
    func selectGrade(_ grade: String) {
        self.selectedGrade = grade
//        self.selectedSubject = nil
//        self.selectedTopic = nil
    }
    
    // Create User and return Result with userId or NSError (Async)
    func createUser(id: String, name: String, email: String, grade: String) async -> Result<String, NSError> {
        do {
            // Create a new user instance
            let newUser = User(id: id, name: name, email: email, grade: grade)
            
            // Save the user to the database and get the user ID
            let user = try await newUser.saveToDatabase()
            
            // Save the new user to session
            userSession.saveToSession(user: newUser)
            
            userSession.createUser(user: newUser)
            
            print("Inserted user with ID: \(user.id)")
            return .success(id) // Return the user ID as success
            
        } catch let error as NSError {
            print("Failed to insert user: \(error.localizedDescription)")
            return .failure(error) // Return the error as failure
        }
    }
    
    // Get User by UserName and return Result
    func getUserByUserName(name: String) async -> Result<User, NSError> {
        do {
            let result = await User.shared.getUserByUserName(name: name)
            
            switch result {
            case .success(let user):
                return .success(user) // Return user inside success case
            case .failure(let error):
                return .failure(error) // Return the failure error as is
            }
        } catch {
            print("Error getting user by username: \(error.localizedDescription)")
            let nsError = NSError(domain: "UserFetchError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Error fetching user by username"])
            return .failure(nsError) // Return a custom error if the try-catch fails
        }
    }
}
