import SwiftUI

// LibraryView
struct LibraryView: View {
    @EnvironmentObject var userSession: UserSession
    @StateObject private var viewModel = StudyPlanViewModel()
    @StateObject private var libraryViewModel = LibraryViewModel()
    @State private var goQuizView = false
    @State private var selectedPlanId: String? = nil // Store the selected plan ID

    private func handleStudyPlanAction(_ plan: StudyPlan) async {
        viewModel.isLoading = true
        defer {
            viewModel.isLoading = false
        }

        switch plan.status {
        case StudyPlanStatusType.notStarted.rawValue:
            await startStudyPlan(plan)
        case StudyPlanStatusType.inProgress.rawValue:
            print("Resuming study plan: \(plan.id)")
        case StudyPlanStatusType.completed.rawValue:
            print("Study plan already completed: \(plan.id)")
        default:
            print("Unknown status: \(plan.status)")
        }
    }

    private func startStudyPlan(_ plan: StudyPlan) async {
        do {
            let result = try await libraryViewModel.createLessonQuiz(planID: plan.id)
            switch result {
            case .success(let quiz):
                print("Quiz created successfully: \(quiz)")
                selectedPlanId = plan.id // Set the selected plan ID to navigate
                goQuizView = true
            case .failure(let error):
                print("Failed to create quiz: \(error.localizedDescription)")
            }
        } catch {
            print("Error calling createLessonQuiz: \(error.localizedDescription)")
        }
    }

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(viewModel.studyPlans, id: \.id) { plan in
                            StudyPlanRow(plan: plan)
                        }
                    }
                    .padding(.bottom, 15)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationDestination(isPresented: $goQuizView) {
            if let planId = selectedPlanId {
                QuizView(studyPlanId: planId) // Pass the selected plan ID to QuizView
            }
        }
        .onAppear {
            guard let userId = userSession.currentUser?.id, !userId.isEmpty else {
                print("Error: User ID is empty.")
                return
            }

            Task {
                await viewModel.getStudyPlans(userId: userId)
                viewModel.isLoading = false
            }
        }
    }
}

struct StudyPlanRow: View {
    let plan: StudyPlan

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Grade: \(plan.grade)")
                    .font(.headline)
                Text("Subject: \(plan.subject)")
                    .font(.subheadline)
                Text("Topic: \(plan.topic)")
                    .font(.subheadline)
                Text("Duration: \(plan.studyDuration) hours")
                    .font(.subheadline)
                Text("Frequency: \(plan.studyFrequency) times/week")
                    .font(.subheadline)
                Text("Status: \(plan.status)")
                    .font(.subheadline)
                Text("Created at: \(plan.createdAt, style: .date)")
                    .font(.subheadline)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)

            StudyPlanButton(plan: plan)
        }
        .background(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1))
        .padding(.horizontal)
    }
}

struct StudyPlanButton: View {
    let plan: StudyPlan

    var body: some View {
        VStack {
            Button(action: {
                Task {
                    await handleStudyPlanAction(plan)
                }
            }) {
                Text(plan.status == StudyPlanStatusType.notStarted.rawValue ? "Start" : "Resume")
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

    private func handleStudyPlanAction(_ plan: StudyPlan) async {
        // Assuming we have access to the LibraryViewModel and ViewModel in the context
        // may need to adjust this part of the code to have access to the correct models in this subview
    }
}
