
import SwiftUI

struct CreateStudyPlanView: View {
    @EnvironmentObject var userSession: UserSession // Access userSession from the environment
    @ObservedObject private var viewModel = StudyPlanViewModel()
    @State var selectedView: Option = .picker
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        ScrollView {  // Make the entire content scrollable
            VStack(spacing: 20) {
                // Access user information from the userSession
//                if let user = userSession.currentUser, !user.name.isEmpty {
//                    Text("Welcome, \(user.name)")
//                } else {
//                    Text("No user logged in")
//                }
                HStack{
                    Text("Create")
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                }
                VStack{
                    Picker("Create Study Plan", selection: $selectedView){
                        ForEach(Option.allCases, id: \.self){
                            Text("\($0.rawValue)")
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    switch selectedView {
                    case .picker:
                        HStack {
                            Text("What is your grade: ")
                                .font(.title3)
                            
                            Menu {
                                ForEach(viewModel.grades, id: \.self) { grade in
                                    Button(grade, action: { viewModel.selectGrade(grade) })
                                }
                            } label: {
                                Label(viewModel.selectedGrade ?? "Select", systemImage: "chevron.down")
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                    .frame(minWidth: 120)
                            }
                        }
                        if let selectedGrade = viewModel.selectedGrade {
                            HStack {
                                Text("Choose subject:")
                                    .font(.title3)
                                
                                Menu {
                                    ForEach(viewModel.subjects(for: selectedGrade), id: \.self) { subject in
                                        Button(subject, action: { viewModel.selectSubject(subject) })
                                    }
                                } label: {
                                    Label(viewModel.selectedSubject ?? "Select", systemImage: "chevron.down")
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                        .frame(minWidth: 120)
                                }
                            }
                        }
                        
                        // Topic Selection
                        if let selectedSubject = viewModel.selectedSubject {
                            HStack {
                                Text("Choose topic: ")
                                    .font(.title3)
                                
                                Menu {
                                    ForEach(viewModel.topics(for: selectedSubject), id: \.self) { topic in
                                        Button(topic, action: { viewModel.selectTopic(topic) })
                                    }
                                } label: {
                                    Label(viewModel.selectedTopic ?? "Select", systemImage: "chevron.down")
                                        .padding()
                                               .background(Color.blue.opacity(0.1))
                                               .cornerRadius(8)
                                        .frame(minWidth: 120)
                                }
                            }
                        }
                    case .scanner:
                        ScannerView(
                            selectedGrade: $viewModel.selectedGrade,
                            selectedSubject: $viewModel.selectedSubject,
                            selectedTopic: $viewModel.selectedTopic
                        )
                        VStack {
                            HStack {
                                Text("Extracted Grade:")
                                    .font(.title3)
                                Text(viewModel.selectedGrade ?? "Select")
                                    .font(.headline)
                            }
                            
                            HStack {
                                Text("Extracted Subject:")
                                    .font(.title3)

                                Text(viewModel.selectedSubject ?? "Select")
                                    .font(.headline)
                            }
                            
                            HStack {
                                Text("Extracted Topic:")
                                    .font(.title3)

                                Text(viewModel.selectedTopic ?? "Select")
                                    .font(.headline)
                            }
                        }


                    }
                }
                // Grade Selection
                
                
                // Subject Selection
//
                
                // Duration Selection
                HStack {
                    Text("How long do you plan to study: ")
                        .font(.title3)
                    
                    Menu {
                        Button("1 week", action: { viewModel.selectedDuration = "1 week" })
                        Button("2 weeks", action: { viewModel.selectedDuration = "2 weeks" })
                        Button("3 weeks", action: { viewModel.selectedDuration = "3 weeks" })
                        Button("1 month", action: { viewModel.selectedDuration = "1 month" })
                    } label: {
                        Label(viewModel.selectedDuration.isEmpty ? "Select" : viewModel.selectedDuration, systemImage: "chevron.down")
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                            .frame(minWidth: 120)
                    }
                }
                
                // Commitment Selection
                HStack {
                    Text("How much time can you dedicate weekly: ")
                        .font(.title3)
                    
                    Menu {
                        Button("1 hour", action: { viewModel.selectedCommitment = "1 hour" })
                        Button("2 hours", action: { viewModel.selectedCommitment = "2 hours" })
                    } label: {
                        Label(viewModel.selectedCommitment.isEmpty ? "Select" : viewModel.selectedCommitment, systemImage: "chevron.down")
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
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                }
                
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Study Plan Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                .disabled(viewModel.isLoading)
                
                // Display ScannerView
                // Pass bindings to ScannerView to allow automatic updates
            }
            .padding()
            .onAppear {
                Task {
                    await viewModel.loadDataSubjectTopics()
                }
            }
        }
        .padding(.bottom, 50)  // Add extra padding at the bottom to make space for the keyboard
    }
    enum Option: String, CaseIterable{
        case picker = "Create Study Plan"
        case scanner = "Scan Notes"
    }
}
