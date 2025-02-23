import Foundation
import SwiftUI

// ViewModel for LibraryViewModel
class LibraryViewModel: ObservableObject {
    @AppStorage("offlineMode") private var offlineMode: Bool = false
    
    // Method to create lesson quiz
    func createLessonQuiz(planID: String) async -> Result<String, NSError> {
        print("Creating quiz for plan ID: \(planID)")
        
        let fileName = "quiz_\(planID)"
        
        // Fetch the lesson plan
        let lessonPlanResult = await LessonPlan.shared.getLessonPlan(studyPlanId: planID)
        
        switch lessonPlanResult {
        case .success(let lessonPlan):
            var createQuizResult: Result<String, NSError> = .failure(NSError())
            
            // 2. Generate the quiz
            if offlineMode {
                // Load offline plan
                createQuizResult = await loadOfflineQuiz(fileName: fileName)
            } else {
                createQuizResult = await lessonPlan.createLessonQuiz()
            }
            
            switch createQuizResult {
            case .success(let quizJson):
                print(quizJson)
                
                // 3. Convert response to Quiz object
                let decodeResult = await Quiz.shared.decodeQuiz(from: quizJson)
                
                switch decodeResult {
                case .success(let quiz):
                    print("decodeQuiz success")
                    print("quiz.studyPlanId: \(quiz.studyPlanId)")
                    print("quiz.questions: \(quiz.questions)")
                    
                    // Convert Quiz object to a JSON string or some other string representation
                    if let quizJsonString = try? JSONEncoder().encode(quiz),
                       let jsonString = String(data: quizJsonString, encoding: .utf8) {
                        
                        // Save to file if offlineMode is false
                        if !offlineMode {
                            // Save for offline use
                            do {
                                try await LocalJSONDataManager.shared.saveJSON(data: jsonString, fileName: fileName)
                                print("✅ Tips saved for offline mode: \(fileName)")
                            } catch {
                                print("❌ Failed to save quiz: \(error.localizedDescription)")
                                return .failure(error as NSError)
                            }
                        }
                        
                        // 4. Save the generated quiz to the database
                        let saveQuizResult = await Quiz.shared.saveToDatabase(from: quiz)
                        
                        switch saveQuizResult {
                        case .success:
                            // 5. Update StudyPlan and LessonPlan status to In Progress
                            let updateStudyPlanResult = await StudyPlan.shared.updateStudyPlan(studyPlanId: planID, status: StudyPlanStatusType.inProgress.rawValue)
                            
                            switch updateStudyPlanResult {
                            case .success:
                                return .success(jsonString)  // Return the JSON string
                            case .failure(let error):
                                print("Failed to update study plan: \(error.localizedDescription)")
                                return .failure(error as NSError)
                            }
                            
                        case .failure(let error):
                            print("Failed to save the quiz: \(error.localizedDescription)")
                            return .failure(error as NSError)
                        }
                    } else {
                        print("Failed to convert Quiz to JSON string")
                        return .failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert Quiz to JSON string"]))
                    }
                    
                case .failure(let error):
                    print("Failed to decode quiz: \(error.localizedDescription)")
                    return .failure(error as NSError)
                }
                
            case .failure(let error):
                print("Failed to create quiz: \(error.localizedDescription)")
                return .failure(error as NSError)
            }
            
        case .failure(let error):
            print("Failed to fetch lesson plan: \(error.localizedDescription)")
            return .failure(error as NSError)
        }
    }

    private func loadOfflineQuiz(fileName: String) async -> Result<String, NSError> {
        // Load data from the JSON file
        guard let result = await LocalJSONDataManager.shared.loadDataFromJSONFile(fileName: fileName, fileExtension: "json") else {
            let error = NSError(domain: "com.yourdomain.LibraryViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "Offline mode enabled, but no saved data found."])
            return .failure(error)
        }
        
        return .success(result)
    }
    
}
