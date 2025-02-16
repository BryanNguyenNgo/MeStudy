import Foundation
// ViewModel for LibraryViewModel
class LibraryViewModel: ObservableObject {

    
    // Method to create lesson quiz
    func createLessonQuiz(planID: String) async -> Result<String, NSError> {
        print("Creating quiz for plan ID: \(planID)")
        
        // 1. Fetch the lesson plan (assuming you have a method to get it)
        let lessonPlanResult = await LessonPlan.shared.getLessonPlan(lessonPlanStudyPlanId: planID)
        
        switch lessonPlanResult {
        case .success(let lessonPlan):
            // 2. Generate the quiz for the fetched lesson plan
            let quizResult = await lessonPlan.createLessonQuiz()
            
            switch quizResult {
            case .success(let quiz):
                print("Generated quiz: \(quiz)")
                // Return success with quiz result as a string
                return .success(quiz)
                
            case .failure(let error):
                // Handle failure to generate the quiz
                print("Failed to generate quiz: \(error.localizedDescription)")
                // Return failure with error as NSError
                return .failure(error as NSError)
            }
            
        case .failure(let error):
            // Handle failure to fetch the lesson plan
            print("Failed to fetch lesson plan: \(error.localizedDescription)")
            // Return failure with error as NSError
            return .failure(error as NSError)
        }
    }

    // Method to update the status of a study plan
    func updateStudyPlanStatus(plan: StudyPlan, newStatus: StudyPlanStatusType) -> StudyPlan {
        var updatedPlan = plan
        updatedPlan.status = newStatus.rawValue
        print("Updated study plan ID: \(plan.id) to status: \(newStatus.rawValue)")
        return updatedPlan
    }
}
