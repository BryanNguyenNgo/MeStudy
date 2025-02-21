import SwiftUI

struct QuizDetailView: View {
    var quiz: Quiz  // The selected quiz passed from QuizView
    
    @State private var isQuizStarted = false
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: String?
    @State private var shortAnswerText: String = ""
    @State private var practiceTaskResponse: String = ""

    var body: some View {
        VStack {
            Text(quiz.quizTitle)
                .font(.largeTitle)
                .padding()

            if currentQuestionIndex < quiz.questions.count {
                let currentQuestion = quiz.questions[currentQuestionIndex]

                Text("Question \(currentQuestionIndex + 1): \(currentQuestion.questionText)")
                    .font(.headline)
                    .padding()

                questionView(for: currentQuestion)  // Extracted function to simplify `body`
            } else {
                Text("No questions available.")
                    .padding()
            }

            Spacer()
            navigationButtons()
        }
        .padding()
        .navigationTitle("Quiz Details")
        .onAppear {
            isQuizStarted = true
        }
    }
    
    /// Function to handle different question types separately
    @ViewBuilder
    private func questionView(for question: Question) -> some View {
        switch question.questionType.rawValue {
        case "multiple_choice":
            multipleChoiceView(for: question)
        case "short_answer":
            shortAnswerView()
        case "practice_task":
            practiceTaskView()
        default:
            Text("Unsupported question type")
        }
    }

    /// Separate function for multiple choice questions
    private func multipleChoiceView(for question: Question) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let options = question.options { // Safely unwrap optional array
                ForEach(options, id: \.self) { answer in
                    HStack {
                        Image(systemName: selectedAnswer == answer ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                        
                        Text(answer)
                            .font(.body)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6)) // Light background for contrast
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedAnswer = answer
                    }
                }
            } else {
                Text("No options available.")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding(.horizontal)
    }


    /// Separate function for short answer questions
    private func shortAnswerView() -> some View {
        TextField("Enter your answer", text: $shortAnswerText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()
    }

    /// Separate function for practice tasks
    private func practiceTaskView() -> some View {
        VStack {
            Text("Complete the practice task:")
                .font(.headline)
            TextEditor(text: $practiceTaskResponse)
                .frame(height: 100)
                .border(Color.gray, width: 1)
                .cornerRadius(5)
                .padding()
        }
    }

    /// Navigation buttons extracted to a separate function
    private func navigationButtons() -> some View {
        HStack(spacing: 20) {
            // Previous Question Button
            if currentQuestionIndex > 0 {
                Button("Previous Question") {
                    currentQuestionIndex -= 1
                    selectedAnswer = nil  // Reset selected answer
                    shortAnswerText = ""   // Reset short answer
                    practiceTaskResponse = ""  // Reset practice task response
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            Spacer()

            // Next Question or Finish Quiz Button
            if currentQuestionIndex < quiz.questions.count - 1 {
                Button("Next Question") {
                    currentQuestionIndex += 1
                    selectedAnswer = nil  // Reset selected answer
                    shortAnswerText = ""   // Reset short answer
                    practiceTaskResponse = ""  // Reset practice task response
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Button("Finish Quiz") {
                    isQuizStarted = false
                    // Handle quiz completion logic here
                    //completeQuiz() // Call function to submit quiz results
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }

}
