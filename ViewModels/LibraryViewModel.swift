import Foundation

// ViewModel for LibraryViewModel
class LibraryViewModel: ObservableObject {
    
    // Method to create lesson quiz
    func createLessonQuiz(planID: String) async -> Result<String, NSError> {
        print("Creating quiz for plan ID: \(planID)")
        

        // 1. Fetch the lesson plan (assuming you have a method to get it)
        let lessonPlanResult = await LessonPlan.shared.getLessonPlan(studyPlanId: planID)
        
        switch lessonPlanResult {
        case .success(let lessonPlan):
            // 2. Generate the quiz for the fetched lesson plan
            let quizResult = await lessonPlan.createLessonQuiz()
            
            switch quizResult {
            case .success(let quiz):
                let quizResult = await Quiz.shared.decodeQuiz(from: quiz)
                
                return .success(quiz)
               
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
