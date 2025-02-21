import SwiftUI

struct CreateStudyPlanView: View {
    @EnvironmentObject var userSession: UserSession // Access userSession from the environment
    @StateObject private var viewModel = StudyPlanViewModel()
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        VStack {
            // Access user information from the userSession
            if let user = userSession.currentUser, !user.name.isEmpty {
                Text("Welcome, \(user.name)")
            } else {
                Text("No user logged in")
            }

            
            Text("Study Plan")
                .font(.largeTitle)
            
            // Grade Selection
            HStack {
                Text("What is your grade: ")
                    .font(.headline)
                
                Menu {
                    ForEach(viewModel.grades, id: \.self) { grade in
                        Button(grade, action: { viewModel.selectGrade(grade) })
                    }
                } label: {
                    Label("\(viewModel.selectedGrade ?? "Select")", systemImage: "chevron.down")
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .frame(minWidth: 120)
                }
            }
            
            // Subject Selection
            if let selectedGrade = viewModel.selectedGrade {
                HStack {
                    Text("Choose subject:")
                        .font(.headline)
                    
                    Menu {
                        ForEach(viewModel.subjects(for: selectedGrade), id: \.self) { subject in
                            Button(subject, action: { viewModel.selectSubject(subject) })
                        }
                    } label: {
                        Label("\(viewModel.selectedSubject ?? "Select")", systemImage: "chevron.down")
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                            .frame(minWidth: 120)
                    }
                }
            }
            
            // Topic Selection
            if let selectedSubject = viewModel.selectedSubject {
                HStack {
                    Text("Choose topic: ")
                        .font(.headline)
                    
                    Menu {
                        ForEach(viewModel.topics(for: selectedSubject), id: \.self) { topic in
                            Button(topic, action: { viewModel.selectTopic(topic) })
                        }
                    } label: {
                        Label("\(viewModel.selectedTopic ?? "Select")", systemImage: "chevron.down")
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                            .frame(minWidth: 120)
                    }
                }
            }
            
            // Duration Selection
            HStack {
                Text("How long do you plan to study: ")
                    .font(.headline)
                
                Menu {
                    Button("2 months", action: { viewModel.selectedDuration = "2 months" })
                    Button("4 months", action: { viewModel.selectedDuration = "4 months" })
                } label: {
                    Label("\(viewModel.selectedDuration.isEmpty == true ? "Select" : viewModel.selectedDuration)", systemImage: "chevron.down")

                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .frame(minWidth: 120)
                }
            }
            
            // Commitment Selection
            HStack {
                Text("How much time can you dedicate weekly: ")
                    .font(.headline)
                
                Menu {
                    Button("1 hour", action: { viewModel.selectedCommitment = "1 hour" })
                    Button("2 hours", action: { viewModel.selectedCommitment = "2 hours" })
                } label: {
                    Label("\(viewModel.selectedCommitment.isEmpty == true ? "Select" : viewModel.selectedCommitment)", systemImage: "chevron.down")
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .frame(minWidth: 120)
                }
            }
            
            // Ensure user has an ID, fallback to empty string if nil
            let userId = userSession.currentUser?.id ?? ""
            
            // Loading Indicator
                        if viewModel.isLoading {
                            ProgressView("Generating Study Plan...")
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                        }
            
            // Extract numeric value safely from string
            let duration = Int(viewModel.selectedDuration.prefix(1)) ?? 0
            let commitment = Int(viewModel.selectedCommitment.prefix(1)) ?? 0
            
            Button(action: {
                Task {
                    let result = await viewModel.generateStudyPlan(
                        userId: userId,
                        grade: viewModel.selectedGrade ?? "",
                        subject: viewModel.selectedSubject ?? "",
                        topic: viewModel.selectedTopic ?? "",
                        duration: duration,
                        commitment: commitment
                    )
                    
                    switch result {
                    case .success(let message):
                        alertMessage = message // Display success message
                        showAlert = true
                    case .failure(let error):
                        alertMessage = "Failed to create study plan: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            }) {
                Text("Generate Study Plan")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Study Plan Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .disabled(viewModel.isLoading)

            // Display Generated Plan
            Text(viewModel.generatedPlan)
                .padding()
                .multilineTextAlignment(.center)
        }
        .padding()
        .onAppear {
            Task {
                await viewModel.loadDataSubjectTopics()
            }
        }
    }
}
