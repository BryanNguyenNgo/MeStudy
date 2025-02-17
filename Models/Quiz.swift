import SwiftUI

enum QuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case shortAnswer = "short_answer"
    case practiceTask = "practice_task"
}

class Question: Identifiable, ObservableObject, Codable, Equatable {
    let id: String
    let type: QuestionType
    let question: String?
    let options: [String]?
    let correctAnswer: String?
    let task: String?
    
    init(id: String, type: QuestionType, question: String? = nil, options: [String]? = nil, correctAnswer: String? = nil, task: String? = nil) {
        self.id = id
        self.type = type
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
        self.task = task
    }

    static func == (lhs: Question, rhs: Question) -> Bool {
        return lhs.id == rhs.id
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, type, question, options, correctAnswer, task
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(QuestionType.self, forKey: .type)
        self.question = try container.decodeIfPresent(String.self, forKey: .question)
        self.options = try container.decodeIfPresent([String].self, forKey: .options)
        self.correctAnswer = try container.decodeIfPresent(String.self, forKey: .correctAnswer)
        self.task = try container.decodeIfPresent(String.self, forKey: .task)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(question, forKey: .question)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encodeIfPresent(correctAnswer, forKey: .correctAnswer)
        try container.encodeIfPresent(task, forKey: .task)
    }
}

class Quiz: Identifiable, ObservableObject, Codable, Equatable {
    let id: String
    let quizTitle: String
    let studyPlanId: String
    let questions: [Question]
    
    init(id: String, quizTitle: String, studyPlanId: String, questions: [Question] = []) {
        self.id = id
        self.quizTitle = quizTitle
        self.studyPlanId = studyPlanId
        self.questions = questions
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.quizTitle = try container.decode(String.self, forKey: .quizTitle)
        self.studyPlanId = try container.decode(String.self, forKey: .studyPlanId)
        self.questions = try container.decodeIfPresent([Question].self, forKey: .questions) ?? []
    }
    
    static func == (lhs: Quiz, rhs: Quiz) -> Bool {
        return lhs.id == rhs.id && lhs.quizTitle == rhs.quizTitle && lhs.studyPlanId == rhs.studyPlanId
    }

    // Shared instance of an empty Quiz
    static let shared = Quiz(id: "default", quizTitle: "Untitled Quiz", studyPlanId: "default", questions: [])

    // Decode from JSON string
    func decodeQuiz(from data: String) async -> Result<Quiz, NSError> {
        guard let jsonData = data.data(using: .utf8) else {
            let error = NSError(domain: "DecodeQuizError", code: 100, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])
            print(error.localizedDescription)
            return .failure(error)
        }
        
        do {
            print("data: \(data)")
            let decoder = JSONDecoder()
            let quiz = try decoder.decode(Quiz.self, from: jsonData)
            
            print("Quiz Title: \(quiz.quizTitle)")
            print("Study Plan ID: \(quiz.studyPlanId)")
            print("Number of Questions: \(quiz.questions.count)")
            
            return .success(quiz)
        } catch let error as NSError {
            print("error in decode quiz: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    // Simulate saving to a database asynchronously
    func saveToDatabase(from quiz: Quiz) async -> Result<String, NSError> {
        // Call the database save logic
        guard let insertedId: String = await DatabaseManager.shared.insertQuizAndQuestions(
            quizId: quiz.id, quizTitle: quiz.quizTitle, studyPlanId: quiz.studyPlanId, questions: quiz.questions
        ) else {
            let error = NSError(domain: "DatabaseError", code: 101, userInfo: [NSLocalizedDescriptionKey: "Failed to save quiz to database."])
            print("Error: \(error.localizedDescription)")

            return .failure(error)
        }
        
        print("Successfully saved into DB. Inserted ID: \(insertedId)")
        return .success(insertedId)
    }

}
