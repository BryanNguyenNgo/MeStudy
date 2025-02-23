import SwiftUI

struct StudyPlanDetailView: View {
    @EnvironmentObject var userSession: UserSession // Access user session from environment
    @StateObject private var viewModel = StudyPlanViewModel()
    @StateObject private var quizViewModel = QuizViewModel()
    @State private var goToQuizDetailView = false
    @State private var selectedQuiz: Quiz?

    var plan: StudyPlan
    var studyPlanId: String

    var body: some View {
        ScrollView {
            Text(plan.topic)
                .font(.title)
                .bold()
            VStack(alignment: .leading, spacing: 12) {
                

                VStack(alignment: .leading, spacing: 4) {
                    infoRow(label: "Grade:", value: plan.grade)
                    infoRow(label: "Subject:", value: plan.subject)
                    infoRow(label: "Study Frequency:", value: "\(plan.studyFrequency) time(s) per week")
                    infoRow(label: "Study Duration:", value: "\(plan.studyDuration) week(s)")
                    infoRow(label: "Status:", value: plan.status ?? "N/A")
                    infoRow(label: "Created At:", value: "\(plan.createdAt)")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                
                Spacer()
                
            }
            .padding()
        }
        .navigationTitle("Details")
        .onAppear {
            Task {
                await quizViewModel.getQuizzes(studyPlanId: studyPlanId)
            }
        }
        .navigationDestination(isPresented: $goToQuizDetailView) {
            if let quiz = selectedQuiz {
                QuizDetailView(quiz: quiz)
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}
