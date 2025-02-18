import SwiftUI

// QuizView
struct QuizView: View {
    @EnvironmentObject var userSession: UserSession // Access the user from the environment
    @StateObject private var quizViewModel = QuizViewModel()  // ViewModel as a @StateObject
    @State private var goToQuizDetailView = false
    @State private var selectedQuiz: Quiz?  // Track the selected quiz

    var studyPlanId: String  // Pass the study plan ID

    private func handleQuizAction(_ quiz: Quiz) async {
        print("Starting quiz: \(quiz.id)")
        selectedQuiz = quiz  // Store the selected quiz
        goToQuizDetailView = true  // Navigate to the quiz detail view
    }

    var body: some View {
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
//        .navigationDestination(isPresented: $goToQuizDetailView) {
//            if let quiz = selectedQuiz {
//                QuizDetailView(quiz: quiz)  // Navigate to the quiz detail view
//            }
//        }
        .onAppear {
            Task {
                await quizViewModel.getQuizzes(studyPlanId: studyPlanId)
            }
        }
    }
}

struct QuizRow: View {
    let quiz: Quiz
    let handleQuizAction: (Quiz) async -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Quiz Title: \(quiz.quizTitle)")
                    .font(.headline)
               
//                Text("Number of Questions: \(quiz.questionCount)")
//                    .font(.subheadline)
//                Text("Created at: \(quiz.createdAt, style: .date)")
//                    .font(.subheadline)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)

            VStack {
                Button(action: {
                    Task {
                        await handleQuizAction(quiz)
                    }
                }) {
                    Text("Start Quiz")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 5)
                .frame(width: 120)
            }
        }
        .background(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1))
        .padding(.horizontal)
    }
}
