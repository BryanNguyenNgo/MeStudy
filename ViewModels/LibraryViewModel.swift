import Foundation

// ViewModel for LibraryViewModel
class LibraryViewModel: ObservableObject {
    
    // Method to create lesson quiz
    func createLessonQuiz(planID: String) async -> Result<String, Error> {
        print("Creating quiz for plan ID: \(planID)")

        // 1. Fetch the lesson plan
        let lessonPlanResult = await LessonPlan.shared.getLessonPlan(studyPlanId: planID)
        
        switch lessonPlanResult {
        case .success(let lessonPlan):
            // 2. Generate the quiz
            let createQuizResult = await lessonPlan.createLessonQuiz()
            
            switch createQuizResult {
            case .success(let quizJson):
                print(quizJson)
                
                // 3. Convert response to Quiz object
                let decodeResult = await Quiz.shared.decodeQuiz(from: quizJson)
                
                switch decodeResult {
                case .success(let quiz):  // ✅ FIXED: Removed unnecessary optional binding
                    print("decodeQuiz success")
                    print("quiz.studyPlanId: \(quiz.studyPlanId)")
                    print("quiz.questions: \(quiz.questions)")
                    
                    // 4. Save the generated quiz to the database
                    let saveQuizResult = await Quiz.shared.saveToDatabase(from: quiz)
                    
                    switch saveQuizResult {
                    case .success:
                        // 5. Update StudyPlan and LessonPlan status to In Progress
                        let updateStudyPlanResult = await StudyPlan.shared.updateStudyPlan(studyPlanId: planID, status: StudyPlanStatusType.inProgress.rawValue)
                        
                        switch updateStudyPlanResult {
                        case .success:
                            return .success(quizJson)
                        case .failure(let error):
                            print("Failed to update study plan: \(error.localizedDescription)")
                            return .failure(error)
                        }
                        
                    case .failure(let error):
                        print("Failed to save the quiz: \(error.localizedDescription)")
                        return .failure(error)
                    }
                    
                case .failure(let error):
                    print("Failed to decode quiz: \(error.localizedDescription)")
                    return .failure(error)
                }
                
            case .failure(let error):
                print("Failed to create quiz: \(error.localizedDescription)")
                return .failure(error)
            }
            
        case .failure(let error):
            print("Failed to fetch lesson plan: \(error.localizedDescription)")
            return .failure(error)
        }
    }

//
//
//    // Method to update the status of a study plan
//    func updateStudyPlanStatus(plan: StudyPlan, newStatus: StudyPlanStatusType) -> StudyPlan {
//        var updatedPlan = plan
//        updatedPlan.status = newStatus.rawValue
//        print("Updated study plan ID: \(plan.id) to status: \(newStatus.rawValue)")
//        return updatedPlan
//    }
}
