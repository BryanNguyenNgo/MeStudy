import SwiftUI

// LibraryView
struct LibraryView: View {
    @EnvironmentObject var userSession: UserSession // Access the user from the environment
    @StateObject private var viewModel = StudyPlanViewModel()  // ViewModel as a @StateObject
    @StateObject private var libraryViewModel = LibraryViewModel()  // ViewModel as a @StateObject
    @State private var goEachPlanView = false
    
    private func handleStudyPlanAction(_ plan: StudyPlan) async {
        switch plan.status {
        case StudyPlanStatusType.notStarted.rawValue:
            print("Starting study plan: \(plan.id)")
            // Logic to update status to "in progress"
            do {
                // Calling the asynchronous method and awaiting the result
                let result = try await libraryViewModel.createLessonQuiz(planID: plan.id)

                // Handle the result (assuming it's a String or other type)
                switch result {
                case .success(let quiz):
                    // Do something with the successful quiz result
                    print("Quiz created successfully: \(quiz)")
//                    goEachPlanView = true
                    
                case .failure(let error):
                    // Handle the error case
                    print("Failed to create quiz: \(error.localizedDescription)")
                }
            } catch {
                // Handle any errors thrown during the async call
                print("Error calling createLessonQuiz: \(error.localizedDescription)")
            }
        case StudyPlanStatusType.inProgress.rawValue:
            print("Resuming study plan: \(plan.id)")
            // Logic to resume
        case StudyPlanStatusType.completed.rawValue:
            print("Study plan already completed: \(plan.id)")
        default:
            print("Unknown status: \(plan.status)")
        }
    }

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                ScrollView {  // ScrollView to make the list scrollable
                    LazyVStack(spacing: 15) {  // LazyVStack for better performance
                        ForEach(viewModel.studyPlans, id: \.id) { plan in
                            HStack {
                                // Text in the first column
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
                                .frame(maxWidth: .infinity) // Ensures text takes up available space

                                // Button in the second column
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
                                    .frame(width: 120)  // You can adjust the width if needed
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray, lineWidth: 1))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 15)  // Added bottom padding for proper spacing
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)  // Ensures ScrollView takes full available space
            }
        }
        .navigationDestination(isPresented: $goEachPlanView) {
                    EachPlanView()
                }
        .onAppear {
            // Unwrap the currentUser's ID and check if it's empty
            if let userId = userSession.currentUser?.id, userId.isEmpty {
                print("Error: User ID is empty.")
            } else if let userId = userSession.currentUser?.id {
                print("User ID: \(userId)")
                Task {
                    await viewModel.getStudyPlans(userId: userId)
                    viewModel.isLoading = false // Move this inside Task to update after loading
                }
            } else {
                print("Error: User is not logged in.")
            }
        }
    }
}
