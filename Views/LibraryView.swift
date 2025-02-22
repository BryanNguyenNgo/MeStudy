import SwiftUI

// LibraryView
struct LibraryView: View {
    @EnvironmentObject var userSession: UserSession
    @StateObject private var viewModel = StudyPlanViewModel()
    @StateObject private var libraryViewModel = LibraryViewModel()
    @State private var goQuizView = false
    @State private var selectedPlanId: String? = nil // Store the selected plan ID

    /// Handles study plan action based on its status.
    func handleStudyPlanAction(_ plan: StudyPlan) async {
        viewModel.isLoading = true
        defer { viewModel.isLoading = false }

        switch plan.status {
        case StudyPlanStatusType.notStarted.rawValue:
            await startStudyPlan(plan)
        case StudyPlanStatusType.inProgress.rawValue:
            print("Resuming study plan: \(plan.id)")
            await resumeStudyPlan(plan)
        case StudyPlanStatusType.completed.rawValue:
            print("Study plan already completed: \(plan.id)")
        default:
            print("Unknown status: \(plan.status)")
        }
    }

    /// Starts a new study plan by creating a quiz.
    private func startStudyPlan(_ plan: StudyPlan) async {
        do {
            let result = try await libraryViewModel.createLessonQuiz(planID: plan.id)
            switch result {
            case .success(let quiz):
                print("Quiz created successfully: \(quiz)")
                await resumeStudyPlan(plan)
            case .failure(let error):
                print("Failed to create quiz: \(error.localizedDescription)")
            }
        } catch {
            print("Error calling createLessonQuiz: \(error.localizedDescription)")
        }
    }

    private func resumeStudyPlan(_ plan: StudyPlan) async {
        DispatchQueue.main.async {
            print("Navigating to QuizView with StudyPlan ID: \(plan.id)")
            self.selectedPlanId = plan.id
            self.goQuizView = true
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    ScrollView {
                        NavigationStack{
                            LazyVStack(spacing: 15) {
                                ForEach(viewModel.studyPlans, id: \.id) { plan in
                                    StudyPlanRow(plan: plan) { selectedPlan in
                                        // Call the asynchronous action from the parent.
                                        Task {
                                            await handleStudyPlanAction(selectedPlan)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 15)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .navigationTitle("Library")
                    }
                }
            }
            
            // The navigationDestination modifier is now inside NavigationStack and always returns a view.
            .navigationDestination(isPresented: $goQuizView) {
                Group {
                    if let planId = selectedPlanId {
                        QuizView(studyPlanId: planId) // Pass the selected plan ID to QuizView
                    } else {
                        EmptyView()
                    }
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
}

// StudyPlanRow displays details of a study plan and contains a StudyPlanButton.
struct StudyPlanRow: View {
    let plan: StudyPlan
    let action: (StudyPlan) async -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
               
                NavigationLink {
                    StudyPlanDetailView()
                } label: {
                    Text("\(plan.topic)")
                        .font(.headline)
                        .foregroundColor(Color.blue)
                }

                Text("\(plan.subject)")
                    .font(.subheadline)
                Text("\(plan.grade)")
                    .font(.subheadline)
               
//                Text("Duration: \(plan.studyDuration) hours")
//                    .font(.subheadline)
//                Text("Frequency: \(plan.studyFrequency) times per week")
//                    .font(.subheadline)
//                Text("Status: \(plan.status ?? "status")")
//                    .font(.subheadline)
//                Text("Created at: \(plan.createdAt, style: .date)")
//                    .font(.subheadline)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)

            StudyPlanButton(plan: plan, action: action)
        }
        .navigationBarBackButtonHidden()
        .background(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1))
        .padding(.horizontal)
    }
}

// StudyPlanButton shows a button for the study plan, calling the action when tapped.
struct StudyPlanButton: View {
    let plan: StudyPlan
    let action: (StudyPlan) async -> Void

    var body: some View {
        VStack {
            Button(action: {
                Task {
                    await action(plan)
                }
            }) {
                Text(
                    plan.status == StudyPlanStatusType.notStarted.rawValue ? "Start" :
                    plan.status == StudyPlanStatusType.inProgress.rawValue ? "Resume" :
                    plan.status == StudyPlanStatusType.completed.rawValue ? "Completed" : "Unknown"
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    plan.status == StudyPlanStatusType.notStarted.rawValue ? Color.blue :
                    plan.status == StudyPlanStatusType.inProgress.rawValue ? Color.orange :
                    Color.green // Color for Completed
                )
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.top, 5)
            .frame(width: 120)
        }
    }

}
