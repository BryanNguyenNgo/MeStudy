import Foundation

class QuizViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var quizzes: [Quiz] = []
    
    private var userId: String = "user123" // You can set this from your UserSession or pass it when initializing

    // Method to get quizzes for a specific study plan
    @MainActor
    func getQuizzes(studyPlanId: String) async {
        self.isLoading = true
        
        do {
            // Fetch the quizzes associated with the study plan
            let fetchedQuizzes = try await fetchQuizzes(studyPlanId: studyPlanId)
            
            // Update the quizzes list
            self.quizzes = fetchedQuizzes
        } catch {
            print("Error fetching quizzes: \(error.localizedDescription)")
        }
        
        self.isLoading = false
    }
    
    // Method that returns quizzes (this can be modified to fetch data from a database or API)
    @MainActor
    private func fetchQuizzes(studyPlanId: String) async throws -> [Quiz] {
        
        let quizzes = try await Quiz.shared.getQuizzes(studyPlanId: studyPlanId)
        print("Fetched quizzes: \(quizzes)")
        
        return quizzes
    }
}
