import Foundation

// ViewModel for LibraryViewModel
class LibraryViewModel: ObservableObject {
    
    // Method to create lesson quiz
    func createLessonQuiz(planID: String) async -> Result<String, NSError> {
        print("Creating quiz for plan ID: \(planID)")
        
        // Fetch or generate the quiz data for the given planID
        let quizResult = await Quiz.shared.decodeQuiz(from: planID)
                        
                        switch quizResult {
                        case .success(let quizOptional):
                            guard let quiz = quizOptional else {
                                let error = NSError(domain: "QuizError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Decoded quiz is nil"])
                                return .failure(error)
                            }

                            // 4. Save the generated lesson plan to the database
                            let saveQuizResult = await Quiz.shared.saveToDatabase(from: quiz)
                            switch saveQuizResult {
                            case .success:
                                return .success("Quiz successfully created and saved.")
                            case .failure(let error):
                                // Handle failure to save the quiz
                                print("Failed to save the quiz: \(error.localizedDescription)")
                                return .failure(error as NSError)
                            }
                        
                        case .failure(let error):
                            // Handle failure to decode the quiz
                            print("Failed to decode quiz: \(error.localizedDescription)")
                            return .failure(error as NSError)
                        }
    }

    func processQuizResults(from quizResults: String) {
        // Implementation here
    }

    // Method to update the status of a study plan
    func updateStudyPlanStatus(plan: StudyPlan, newStatus: StudyPlanStatusType) -> StudyPlan {
        var updatedPlan = plan
        updatedPlan.status = newStatus.rawValue
        print("Updated study plan ID: \(plan.id) to status: \(newStatus.rawValue)")
        return updatedPlan
    }
}
