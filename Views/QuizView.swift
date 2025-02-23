import SwiftUI

// QuizView
struct QuizView: View {
    @EnvironmentObject var userSession: UserSession // Access the user session
    @StateObject private var quizViewModel = QuizViewModel()  // ViewModel as a @StateObject
    @State private var goToQuizDetailView = false
    @State private var selectedQuiz: Quiz?  // Track the selected quiz

    var studyPlanId: String  // Pass the study plan ID

    private func handleQuizAction(_ quiz: Quiz) {
        print("Starting quiz: \(quiz.id)")
        selectedQuiz = quiz  // Store the selected quiz
        goToQuizDetailView = true  // Trigger navigation to QuizDetailView
    }

    var body: some View {
        NavigationStack {
            VStack {
                if quizViewModel.isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(quizViewModel.quizzes, id: \.id) { quiz in
                                QuizRow(quiz: quiz, handleQuizAction: handleQuizAction)
                            }
                        }
                        .padding(.bottom, 15)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationDestination(isPresented: $goToQuizDetailView) {
                if let quiz = selectedQuiz {
                    QuizDetailView(quiz: quiz)  // Navigate to the quiz detail view
                } else {
                    EmptyView()
                }
            }
            .onAppear {
                Task {
                    await quizViewModel.getQuizzes(studyPlanId: studyPlanId)
                }
            }
        }
    }
}

// MARK: - QuizRow View
struct QuizRow: View {
    let quiz: Quiz
    let handleQuizAction: (Quiz) -> Void  // Closure with a Quiz argument

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Quiz Title: \(quiz.quizTitle)")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)

            Button(action: {
                handleQuizAction(quiz)  // Pass the quiz object
            }) {
                Text("Start Quiz")
                    .frame(width: 120)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .background(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1))
        .padding(.horizontal)
    }
}
