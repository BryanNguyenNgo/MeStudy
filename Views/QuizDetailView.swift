
import SwiftUI

// QuizDetailView
struct QuizDetailView: View {
    var quiz: Quiz  // The selected quiz passed from QuizView
    
    @State private var isQuizStarted = false
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: String?
    
    var body: some View {
VStack {
//            Text(quiz.quizTitle)
//                .font(.largeTitle)
//                .padding()
//
//           
//
//            // Display current question
//            if !quiz.questions.isEmpty {
//                let currentQuestion = quiz.questions[currentQuestionIndex]
//                
//                if let currentQuestion = currentQuestion {
//                    Text("Question \(currentQuestionIndex + 1): \(currentQuestion.questionText)")
//                        .font(.headline)
//                        .padding()
//                } else {
//                    Text("Question \(currentQuestionIndex + 1): N/A")
//                        .font(.headline)
//                        .padding()
//                }
//
//
//                // Display possible answers
//                ForEach(currentQuestion?.answers ?? [], id: \.self) { answer in
//                    Button(action: {
//                        selectedAnswer = answer
//                    }) {
//                        Text(answer)
//                            .padding()
//                            .background(selectedAnswer == answer ? Color.blue : Color.gray)
//                            .foregroundColor(.white)
//                            .cornerRadius(8)
//                    }
//                    .padding(.top, 5)
//                }
//            } else {
//                Text("No questions available.")
//                    .padding()
//            }
//
//            Spacer()
//
//            if currentQuestionIndex < quiz.questions.count - 1 {
//                Button("Next Question") {
//                    currentQuestionIndex += 1
//                    selectedAnswer = nil  // Reset selected answer
//                }
//                .padding()
//                .background(Color.green)
//                .foregroundColor(.white)
//                .cornerRadius(8)
//            } else {
//                Button("Finish Quiz") {
//                    isQuizStarted = false
//                    // Handle quiz completion logic here
//                }
//                .padding()
//                .background(Color.orange)
//                .foregroundColor(.white)
//                .cornerRadius(8)
//            }
//        }
//        .padding()
//        .navigationTitle("Quiz Details")
//        .onAppear {
//            // Initialize quiz start
//            isQuizStarted = true
     }
   }
}
