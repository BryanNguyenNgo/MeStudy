import Foundation

enum StudyPlanStatusType: String {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"
}


// Step 1: Alarm StudyPlan
class StudyPlan: Identifiable, ObservableObject, Equatable {
    let id: String  // Conforms to Identifiable
    var userId: String
    var grade: String
    var subject: String
    var topic: String
    var studyDuration: Int // months
    var studyFrequency: Int // hours per week
    var createdAt: Date
    var apiKey: String? // Optional, to be set dynamically
    var status: String?
    
    // Initialize with study plan or default values
    init(id: String, userId: String, grade: String, subject: String, topic: String, studyDuration: Int, studyFrequency: Int, status: String) {
        self.id = id
        self.userId = userId
        self.grade = grade
        self.subject = subject
        self.topic = topic
        self.studyDuration = studyDuration
        self.studyFrequency = studyFrequency
        self.createdAt = Date()  // Move assignment here after initializing properties
        self.status = status
    }
    
    // Conformance to Equatable
    static func == (lhs: StudyPlan, rhs: StudyPlan) -> Bool {
        return lhs.id == rhs.id &&
        lhs.userId == rhs.userId &&
        lhs.grade == rhs.grade &&
        lhs.subject == rhs.subject &&
        lhs.topic == rhs.topic &&
        lhs.studyDuration == rhs.studyDuration &&
        lhs.studyFrequency == rhs.studyFrequency &&
        lhs.status == rhs.status &&
        lhs.createdAt == rhs.createdAt &&
        lhs.apiKey == rhs.apiKey
    }
    
    // CodingKeys to exclude the id from decoding
    enum CodingKeys: String, CodingKey {
        case userId
        case grade
        case subject
        case topic
        case studyDuration
        case studyFrequency
        case status
        case createdAt
    }
    // Function to load the API key securely from a config file
    
    
    func loadApiKey() async -> String? {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let apiKey = plist["OpenAI_API_Key"] as? String else {
            return nil
        }
        return apiKey
    }
    
    // Function to generate the study plan
    func generatePlan() async -> Result<String, NSError> {
        print("Starting generatePlan()...")  // Debug start
        
        // Prepare the prompt for the API call
        let prompt = """
            Generate a study plan for a \(self.grade) student, subject \(self.subject) about topic \(self.topic) for them to complete in \(self.studyDuration) months and to study for \(self.studyFrequency) hour(s) per week.

            Divide the study plan into weekly modules, but only generate a plan for the first week.

            - Clearly outline goals for the week.  
            - Include milestones for progress tracking.  
            - Provide a structured timetable (hours/day or tasks/day).  
            - Suggest relevant resources.  

            Output the response in **valid JSON format** with this structure, do not return "json" word:
            {
                "studyPlanId": "\(self.id)",
                "grade": "\(self.grade)",
                "subject": "\(self.subject)",
                "topic": "\(self.topic)",
                "week": "1",
                "goals": "",
                "milestones": "",
                "timetable": {
                    "session": "",
                    "learning_tasks": [{"task": "", "duration": ""}],
                    "practice_tasks": [{"task": "", "duration": ""}]
                },
                "resources": ""
            }
        """
        
       
            // Call the API and await the result
            let apiResult = try await APIManager.shared.callOpenAIAPI(prompt: prompt)
            
            // Return success with result
            return apiResult
        
    }

    // Function to save study plan to database
    func saveToDatabase() async -> Result<String, NSError> {
        do {
            guard let insertedId: String = await DatabaseManager.shared.insertStudyPlan(
                id: self.id,
                userId: self.userId,
                grade: self.grade,
                subject: self.subject,
                topic: self.topic,
                studyDuration: self.studyDuration,
                studyFrequency: self.studyFrequency,
                status: self.status ?? StudyPlanStatusType.notStarted.rawValue // ✅ Provide a default value if nil
            ) else {
                return .failure(NSError(domain: "DatabaseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to insert study plan"]))
            }
            
            return .success(insertedId) // ✅ Return UUID
        } catch {
            return .failure(NSError(domain: "SaveError", code: 500, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
        }
    }
    // Method to retrieve study plans from the database for a specific userId
    func getStudyPlans(userId: String) async -> [StudyPlan] {
            do {
                let studyPlans = await DatabaseManager.shared.getStudyPlans(userId: userId)
                
                // Return the mapped StudyPlans to the main actor
                return studyPlans.map { studyPlan in
                    StudyPlan( id: studyPlan.id, userId: studyPlan.userId, grade: studyPlan.grade, subject: studyPlan.subject, topic: studyPlan.topic, studyDuration: studyPlan.studyDuration, studyFrequency: studyPlan.studyFrequency, status: studyPlan.status ?? StudyPlanStatusType.notStarted.rawValue)
                }
            } catch {
                print("Error retrieving study plans: \(error)")
                return []
            }
        }

}
