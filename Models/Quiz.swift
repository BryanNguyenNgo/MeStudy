import SwiftUI

enum QuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case shortAnswer = "short_answer"
    case practiceTask = "practice_task"
}

class Question: Identifiable, ObservableObject, Codable, Equatable {
    let id: String
    let quizId: String?
    let questionType: QuestionType
    let questionText: String?
    let options: [String]?
    let correctAnswer: String?
    let questionTask: String?
    
    init(id: String, quizId: String, questionType: QuestionType, questionText: String? = nil, options: [String]? = nil, correctAnswer: String? = nil, questionTask: String? = nil) {
        self.id = id
        self.quizId = quizId
        self.questionType = questionType
        self.questionText = questionText
        self.options = options
        self.correctAnswer = correctAnswer
        self.questionTask = questionTask
    }

    static func == (lhs: Question, rhs: Question) -> Bool {
        return lhs.id == rhs.id
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, quizId, questionType, questionText, options, questionTask
        case correctAnswer
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.quizId = try container.decode(String.self, forKey: .quizId)
        self.questionType = try container.decode(QuestionType.self, forKey: .questionType)
        self.questionText = try container.decodeIfPresent(String.self, forKey: .questionText)
        self.options = try container.decodeIfPresent([String].self, forKey: .options)
        self.correctAnswer = try container.decodeIfPresent(String.self, forKey: .correctAnswer)
        self.questionTask = try container.decodeIfPresent(String.self, forKey: .questionTask)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(quizId, forKey: .quizId)
        try container.encode(questionType, forKey: .questionType)
        try container.encodeIfPresent(questionText, forKey: .questionText)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encodeIfPresent(correctAnswer, forKey: .correctAnswer)
        try container.encodeIfPresent(questionTask, forKey: .questionTask)
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

    private enum CodingKeys: String, CodingKey {
        case id, studyPlanId, questions
        case quizTitle
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.quizTitle = try container.decode(String.self, forKey: .quizTitle)
        self.studyPlanId = try container.decode(String.self, forKey: .studyPlanId)
        self.questions = try container.decodeIfPresent([Question].self, forKey: .questions) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(quizTitle, forKey: .quizTitle)
        try container.encode(studyPlanId, forKey: .studyPlanId)
        try container.encode(questions, forKey: .questions)
    }

    static func == (lhs: Quiz, rhs: Quiz) -> Bool {
        return lhs.id == rhs.id && lhs.quizTitle == rhs.quizTitle && lhs.studyPlanId == rhs.studyPlanId
    }

    // Shared instance of an empty Quiz
    static let shared = Quiz(id: "default", quizTitle: "Untitled Quiz", studyPlanId: "default", questions: [])

    // Decode from JSON string
    func decodeQuiz(from data: String) async -> Result<Quiz, NSError> {
        
        do {
            let jsonData = try await StringUtils.shared.cleanJSONString(from: data)
            print("data: \(data)")
            let decoder = JSONDecoder()
            // error below //
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
    // Method to retrieve study plans from the database for a specific userId
    func getQuizzes(studyPlanId: String) async -> [Quiz] {
      
            let quizzes = await DatabaseManager.shared.getQuizzes(studyPlanId: studyPlanId)
            // Return the retrieved quizzes
            return quizzes
       
    }
    
    // Method to update question's user answer
    func updateAnswer(for questionId: String, answer: String) async -> Result<String, NSError> {
        
            let isSuccess = await DatabaseManager.shared.updateAnswer(for: questionId, answer: answer)
            
            if isSuccess {
                return .success("Answer updated successfully")
            } else {
                return .failure(NSError(domain: "Quiz", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to update answer"]))
            }
        
    }
    // Method to update all question's user answers
    func submitQuiz(studyPlanId: String, quizId: String, answers: [String: String]) async -> Result<String, NSError> {
        
            // Call DatabaseManager to update answers and get the correct answer count
            guard let correctAnswerCount = await DatabaseManager.shared.submitQuiz(studyPlanId: studyPlanId, quizId: quizId, answers: answers) else {
                return .failure(NSError(domain: "Quiz", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to update answer for quiz \(quizId)"]))
            }
            
            // Return success message with the number of correct answers
            return .success("All answers updated successfully. Correct answers: \(correctAnswerCount)/4")
        
    }




}
