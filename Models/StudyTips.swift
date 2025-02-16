import Foundation

class StudyTips: Identifiable, ObservableObject, Equatable {
    
    let id: String  // Conforms to Identifiable
    var grade: String
    var subject: String
    var topic: String
    var tips: [String]
    
    static let shared = StudyTips(grade: "", subject: "", topic: "", tips: [])
   
    
    // Initializer
    init(grade: String, subject: String, topic: String, tips: [String] = []) {
        self.id = UUID().uuidString  // Correct UUID conversion
        self.grade = grade
        self.subject = subject
        self.topic = topic
        self.tips = tips
    }
    
    // Conformance to Equatable
    static func == (lhs: StudyTips, rhs: StudyTips) -> Bool {
        return lhs.id == rhs.id &&
        lhs.grade == rhs.grade &&
        lhs.subject == rhs.subject &&
        lhs.topic == rhs.topic &&
        lhs.tips == rhs.tips
    }
    
    func generateStudyTips() async -> Result<String, NSError> {
        print("Starting generateStudyTips()...")  // Debug start
        
        // Prepare the prompt for the API call
        let prompt = """
            Generate encouraging study tips for a \(self.grade) student, subject \(self.subject) for topic \(self.topic).
            
            Provide the 5 study tips in a JSON format with the following structure, do not return "json" word:
            {
                "grade": "\(self.grade)",
                "subject": "\(self.subject)",
                 "topic": "\(self.topic)",
                "tips": [
                    "📚 Break study into smaller, manageable sessions.",
                    "💡 Take regular breaks to keep your mind fresh.",
                    "📝 Use active recall and spaced repetition.",
                    "🌟 Stay organized and plan ahead."
                ]
            }
            Ensure that the tips are practical and motivational to help the student succeed.
        """
        
        do {
            // Call the API and await the result
            let apiResult = try await APIManager.shared.callOpenAIAPI(prompt: prompt)
            
            // Return success with result
            return apiResult
        } catch {
            // Handle any errors and return failure with NSError
            print("Error generating study tips: \(error.localizedDescription)")
            return .failure(error as NSError)
        }
    }
}

