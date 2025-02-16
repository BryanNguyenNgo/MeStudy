import Foundation

// Define the structure of the "LearningTask" and "PracticeTask"
class LessonPlanTask: Identifiable, ObservableObject, Codable, Equatable {
    let id: String
    var task: String
    var duration: String
    
    
    init(id: String, task: String, duration: String) {
        self.id = id
        self.task = task
        self.duration = duration
    }
    
    // Required for Equatable
    static func == (lhs: LessonPlanTask, rhs: LessonPlanTask) -> Bool {
        return lhs.id == rhs.id && lhs.task == rhs.task && lhs.duration == rhs.duration
    }
    
    // CodingKeys to exclude the id from decoding
    enum CodingKeys: String, CodingKey {
        case task
        case duration
    }
    
    // Required initializer for Decodable
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let task = try container.decode(String.self, forKey: .task)
        let duration = try container.decode(String.self, forKey: .duration)
        
        self.init(id: UUID().uuidString, task: task, duration: duration)  // Generate a new UUID for the id
    }
}

// Define the structure of the "Timetable" class
class Timetable: Identifiable, ObservableObject, Codable, Equatable {
    let id: String
    var session: String
    var learning_tasks: [LessonPlanTask]
    var practice_tasks: [LessonPlanTask]
    
    init(session: String, learning_tasks: [LessonPlanTask], practice_tasks: [LessonPlanTask]) {
        self.id = UUID().uuidString  // Correct UUID conversion
        self.session = session
        self.learning_tasks = learning_tasks
        self.practice_tasks = practice_tasks
    }
    
    // Required for Equatable
    static func == (lhs: Timetable, rhs: Timetable) -> Bool {
        return lhs.id == rhs.id &&
               lhs.session == rhs.session &&
               lhs.learning_tasks == rhs.learning_tasks &&
               lhs.practice_tasks == rhs.practice_tasks
    }
    
    // CodingKeys to exclude the id from decoding
    enum CodingKeys: String, CodingKey {
        case session
        case learning_tasks
        case practice_tasks
    }
    
    // Required initializer for Decodable
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let session = try container.decode(String.self, forKey: .session)
        let learningTasks = try container.decode([LessonPlanTask].self, forKey: .learning_tasks)
        let practiceTasks = try container.decode([LessonPlanTask].self, forKey: .practice_tasks)
        
        self.init(session: session, learning_tasks: learningTasks, practice_tasks: practiceTasks)
    }
}

// Define the main "LessonPlan" class
class LessonPlan: Identifiable, ObservableObject, Codable, Equatable {
    let id: String
    var lessonPlanStudyPlanId: String
    var grade: String
    var subject: String
    var topic: String
    var week: String
    var goals: String
    var milestones: String
    var resources: String
    var timetable: Timetable
    
    static let shared = LessonPlan(lessonPlanStudyPlanId: "", grade:"", subject: "", topic: "", week: "", goals: "", milestones: "", resources: "", timetable: Timetable(session: "", learning_tasks: [], practice_tasks: []))
    
    init(lessonPlanStudyPlanId: String, grade: String,subject: String,topic: String, week: String, goals: String, milestones: String, resources: String, timetable: Timetable) {
        self.id = UUID().uuidString  // Correct UUID conversion
        self.lessonPlanStudyPlanId = lessonPlanStudyPlanId
        self.grade = grade
        self.subject = subject
        self.topic = topic
        self.week = week
        self.goals = goals
        self.milestones = milestones
        self.resources = resources
        self.timetable = timetable
    }
    
    // Required for Equatable
    static func == (lhs: LessonPlan, rhs: LessonPlan) -> Bool {
        return lhs.id == rhs.id &&
        lhs.lessonPlanStudyPlanId == rhs.lessonPlanStudyPlanId &&
                lhs.grade == rhs.grade &&
                lhs.subject == rhs.subject &&
                lhs.topic == rhs.topic &&
               lhs.week == rhs.week &&
               lhs.goals == rhs.goals &&
               lhs.milestones == rhs.milestones &&
               lhs.resources == rhs.resources &&
               lhs.timetable == rhs.timetable
    }
    
    // CodingKeys to exclude the id from decoding
    enum CodingKeys: String, CodingKey {
        case lessonPlanStudyPlanId
        case grade
        case subject
        case topic
        case week
        case goals
        case milestones
        case resources
        case timetable
    }
    
    // Required initializer for Decodable
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lessonPlanStudyPlanId = try container.decode(String.self, forKey: .lessonPlanStudyPlanId)
        let grade = try container.decode(String.self, forKey: .grade)
        let subject = try container.decode(String.self, forKey: .subject)
        let topic = try container.decode(String.self, forKey: .topic)
        let week = try container.decode(String.self, forKey: .week)
        let goals = try container.decode(String.self, forKey: .goals)
        let milestones = try container.decode(String.self, forKey: .milestones)
        let resources = try container.decode(String.self, forKey: .resources)
        let timetable = try container.decode(Timetable.self, forKey: .timetable)
        
        self.init(lessonPlanStudyPlanId: lessonPlanStudyPlanId, grade: grade, subject: subject, topic: topic, week: week, goals: goals, milestones: milestones, resources: resources, timetable: timetable)
    }
    // Decode from JSON string
    func decodeLessonPlan(from data: String) async -> Result<LessonPlan?, NSError> {
        guard let jsonData = data.data(using: .utf8) else {
            let error = NSError(domain: "DecodeLessonPlanError", code: 100, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])
            print(error.localizedDescription)
            return .failure(error)
        }
        
        do {
            // Parse JSON response using JSONDecoder to decode into LessonPlan
            let decoder = JSONDecoder()
            let lessonPlan = try decoder.decode(LessonPlan.self, from: jsonData)
            
            // Print out the decoded values
            print("Study Plan for: \(lessonPlan.grade)")
            print("subject: \(lessonPlan.subject)")
            print("topic : \(lessonPlan.topic)")
            print("week \(lessonPlan.week)")
            print("Goals: \(lessonPlan.goals)")
            print("Milestones: \(lessonPlan.milestones)")
            print("Resources: \(lessonPlan.resources)")
            print("Session: \(lessonPlan.timetable.session)")
            print("Learning Tasks: \(lessonPlan.timetable.learning_tasks.map { $0.task }.joined(separator: ", "))")
            print("Practice Tasks: \(lessonPlan.timetable.practice_tasks.map { $0.task }.joined(separator: ", "))")
            
            return .success(lessonPlan)
        } catch let error as NSError {
            print("Error decoding JSON: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    // Simulate saving to a database asynchronously
    func saveToDatabase(from lessonPlan: LessonPlan) async -> Result<String, NSError> {
        print("Attempting to save lesson plan with ID: \(lessonPlan.id)")
        print("Grade: \(lessonPlan.grade)")
        print("Subject: \(lessonPlan.subject)")
        print("Topic: \(lessonPlan.topic)")
        print("Week: \(lessonPlan.week)")
        print("Goals: \(lessonPlan.goals)")
        print("Milestones: \(lessonPlan.milestones)")
        print("Resources: \(lessonPlan.resources)")
        print("Timetable: \(lessonPlan.timetable)")

        // Call the database save logic
        guard let insertedId: String = await DatabaseManager.shared.insertLessonPlan(
            id: lessonPlan.id,
            lessonPlanStudyPlanId:lessonPlan.lessonPlanStudyPlanId,
            grade: lessonPlan.grade,
            subject: lessonPlan.subject,
            topic: lessonPlan.topic,
            week: lessonPlan.week,
            goals: lessonPlan.goals,
            milestones: lessonPlan.milestones,
            resources: lessonPlan.resources,
            timetable: lessonPlan.timetable
        ) else {
            let error = NSError(domain: "DatabaseError", code: 101, userInfo: [NSLocalizedDescriptionKey: "Failed to save lesson plan to database."])
            print("Error: \(error.localizedDescription)")

            // Additional debugging for foreign key issues
//            print("Checking related foreign key dependencies...")
//            let parentExists = await DatabaseManager.shared.checkParentExists(for: lessonPlan)
//            print("Parent record exists: \(parentExists)")

            return .failure(error)
        }
        
        print("Successfully saved into DB. Inserted ID: \(insertedId)")
        return .success(insertedId)
    }
    
    // Function to get lesson plan from the database
    func getLessonPlan(lessonPlanStudyPlanId: String) async -> Result<LessonPlan, NSError> {
        do {
            if let lessonPlan = await DatabaseManager.shared.getLessonPlan(lessonPlanStudyPlanId: lessonPlanStudyPlanId) {
                return .success(lessonPlan)
            } else {
                let error = NSError(domain: "com.example.app", code: 404, userInfo: [NSLocalizedDescriptionKey: "Lesson plan not found."])
                return .failure(error)
            }
        } catch {
            return .failure(error as NSError)
        }
    }

    // Function to create a lesson quiz
    func createLessonQuiz() async -> Result<String, NSError> {
        
            // Generate quiz based on the lesson plan
        let quizResult = await self.generateQuiz()
            
            switch quizResult {
            case .success(let quiz):
                // Return success with the generated quiz information
                print("Generated Quiz: \(quiz)")
                return .success(quiz) // Return success with the quiz result
            case .failure(let error):
                // Return failure if quiz generation fails
                print("Failed to generate quiz: \(error.localizedDescription)")
                return .failure(NSError(domain: "QuizGenerationError", code: 500, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
            }
       
    }


    // Function to generate the quiz based on lesson plan
    func generateQuiz() async -> Result<String, NSError> {
        let prompt = """
        Create a quiz based on the following study plan for a grade \(self.grade) student studying \(self.subject) on the topic of \(self.topic) in week \(self.week). The goal of the quiz is to assess the student's understanding of the material outlined in the study plan.

        Study Plan Details:
        - Goal: \(self.goals)
        - Milestones: \(self.milestones)
        - Timetable:
            - Session: \(self.timetable.session ?? "")
            - Learning Tasks:
                - Task 1: \(self.timetable.learning_tasks[safe: 0]?.task ?? "N/A") (\(self.timetable.learning_tasks[safe: 0]?.duration ?? "N/A"))
                - Task 2: \(self.timetable.learning_tasks[safe: 1]?.task ?? "N/A") (\(self.timetable.learning_tasks[safe: 1]?.duration ?? "N/A"))
                - Task 3: \(self.timetable.learning_tasks[safe: 2]?.task ?? "N/A") (\(self.timetable.learning_tasks[safe: 2]?.duration ?? "N/A"))
            - Practice Tasks:
               - Task 1: \(self.timetable.practice_tasks[safe: 0]?.task ?? "N/A")
               - Task 2: \(self.timetable.practice_tasks[safe: 1]?.task ?? "N/A")

        The quiz should contain the following:
        1. Multiple choice questions to assess understanding of the eight parts of speech in English grammar.
        2. A few short-answer questions that require the student to define each part of speech.
        3. A practice task where the student identifies parts of speech in example sentences.

        Output the quiz in **valid JSON format** with this structure, do not return the word "json":
        Sample 
        {
            "quiz_title": "Grammar Quiz on Parts of Speech",
            "lessonPlanStudyPlanId": "\(self.lessonPlanStudyPlanId)",
            "questions": [
                {
                    "type": "multiple_choice",
                    "question": "Which of the following is an example of a noun?",
                    "options": ["Dog", "Run", "Quickly", "Under"],
                    "correct_answer": "Dog"
                },
                {
                    "type": "short_answer",
                    "question": "Define the term 'verb'."
                },
                {
                    "type": "multiple_choice",
                    "question": "Which of the following sentences contains a preposition?",
                    "options": [
                        "She ran quickly.",
                        "He went under the bridge.",
                        "The dog is brown.",
                        "They played in the park."
                    ],
                    "correct_answer": "He went under the bridge."
                },
                {
                    "type": "practice_task",
                    "task": "Identify the parts of speech in the following sentence: 'The quick brown fox jumped over the lazy dog.'"
                }
            ]
        }
        """
        
      
               // Call the API and await the result
               let apiResult = await APIManager.shared.callOpenAIAPI(prompt: prompt)
               
               // Return success with the result wrapped in Result type
               return apiResult
    }


}
// Safe Array Index Access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
