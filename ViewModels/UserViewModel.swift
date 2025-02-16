
import Foundation

class UserViewModel: ObservableObject {
    private let userSession: UserSession
    
    @Published var selectedGrade: String? = nil  // Make this optional
   
    // For UI display
    @Published var grades: [String] = []
   
    init(userSession: UserSession) {
          self.userSession = userSession
      }
    // Load data from JSON for grades, subjects and topics
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
        
    func selectGrade(_ grade: String) {
        self.selectedGrade = grade
//        self.selectedSubject = nil
//        self.selectedTopic = nil
    }
    // Create User and return Result with userId or NSError (Async)
    func createUser(name: String, email: String, grade: String) async -> Result<String, NSError> {
        do {
            // Create a new user instance
            let newUser = User(name: name, email: email, grade: grade)
            
            // Save the user to the database and get the user ID
            let id = try await newUser.saveToDatabase()
            
            // Save the new user to session
            userSession.saveToSession(user: newUser)
            
            userSession.createUser(user: newUser)
            
            print("Inserted user with ID: \(id)")
            return .success(id) // Return the user ID as success
            
        } catch let error as NSError {
            print("Failed to insert user: \(error.localizedDescription)")
            return .failure(error) // Return the error as failure
        }
    }
    

}
