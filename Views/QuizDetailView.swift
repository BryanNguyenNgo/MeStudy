import SwiftUI

struct QuizDetailView: View {
    var quiz: Quiz  // The selected quiz passed from QuizView
    @StateObject private var viewModel = QuizViewModel()  // ViewModel as a @StateObject
    @State private var isQuizStarted = false
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: [String: String] = [:] // Track selected answers per question
    @State private var shortAnswerText: String = ""
    @State private var practiceTaskResponse: String = ""

    @State private var userAnswers: [String: String] = [:]  // Store answers for all questions
    
    @State private var promptMessage: String?  // Holds success or error message
    @State private var showMessage: Bool = false  // Controls message display
    
    var body: some View {
        VStack {
            Text(quiz.quizTitle)
                .font(.largeTitle)
                .padding()

            if currentQuestionIndex < quiz.questions.count {
                let currentQuestion = quiz.questions[currentQuestionIndex]

                Text("Question \(currentQuestionIndex + 1): \(currentQuestion.questionText ?? "Question")")
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
            shortAnswerView(for: question)
        case "practice_task":
            practiceTaskView(for: question)
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
                        Image(systemName: selectedAnswer[question.id] == answer ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.blue)
                        
                        Text(answer)
                            .font(.body)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6)) // Light background for contrast
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedAnswer[question.id] = answer
                        userAnswers[question.id] = answer  // Save the selected answer
                        
                        // Update the answer incrementally
                        Task {
                            let result = await viewModel.updateAnswer(for: question.id, answer: answer)
                            switch result {
                            case .success:
                                print("Answer updated successfully")
                            case .failure(let error):
                                print("Error updating answer: \(error.localizedDescription)")
                            }
                        }
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
    private func shortAnswerView(for question: Question) -> some View {
        VStack(alignment: .leading) {
            TextField("Enter your answer", text: $shortAnswerText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: shortAnswerText) { newText in
                    userAnswers[question.id] = newText
                    
                    Task {
                        let result = await viewModel.updateAnswer(for: question.id, answer: newText)
                        switch result {
                        case .success:
                            print("Answer updated successfully")
                        case .failure(let error):
                            print("Error updating answer: \(error.localizedDescription)")
                        }
                    }
                }
        }
        .padding()
    }

    /// Separate function for practice task questions
    private func practiceTaskView(for question: Question) -> some View {
        VStack {
            Text("Complete the practice task:")
                .font(.headline)
            TextEditor(text: $practiceTaskResponse)
                .frame(height: 100)
                .border(Color.gray, width: 1)
                .cornerRadius(5)
                .padding()
                .onChange(of: practiceTaskResponse) { newText in
                    userAnswers[question.id] = newText

                    Task {
                        let result = await viewModel.updateAnswer(for: question.id, answer: newText)
                        switch result {
                        case .success:
                            print("Answer updated successfully")
                        case .failure(let error):
                            print("Error updating answer: \(error.localizedDescription)")
                        }
                    }
                }
        }
        .padding()
    }

    /// Navigation buttons extracted to a separate function
    private func navigationButtons() -> some View {
        HStack(spacing: 20) {
            // Previous Question Button
            if currentQuestionIndex > 0 {
                Button("Previous Question") {
                    currentQuestionIndex -= 1
                    resetInputs()
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
                    resetInputs()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Button("Complete Quiz") {
                    isQuizStarted = false
                    // Submit all answers when the quiz is complete
                   Task {
                       let result = await viewModel.submitQuiz(studyPlanId: quiz.studyPlanId, quizId: quiz.id, answers: userAnswers)
                       DispatchQueue.main.async {
                           switch result {
                           case .success(let message):
                               promptMessage = message
                           case .failure(let error):
                               promptMessage = "Error: \(error.localizedDescription)"
                           }
                           showMessage = true
                       }
                   }
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .alert(isPresented: $showMessage) {
                Alert(title: Text("Quiz Submission"), message: Text(promptMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
    }

    /// Function to reset inputs when navigating between questions
    private func resetInputs() {
        shortAnswerText = ""
        practiceTaskResponse = ""
    }
}
