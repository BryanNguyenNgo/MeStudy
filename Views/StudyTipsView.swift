import SwiftUI

struct StudyTipsView: View {
    @StateObject private var viewModel = StudyTipsViewModel()
    @State private var tips: [String] = [] // Make tips mutable with @State
    @State private var alertMessage: String? = nil // To hold alert message
    @State private var showAlert = false // To control alert presentation
    @State private var isLoading = false // To track loading state
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Study Tips")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top)
            
            // Grade Selection
            HStack {
                Text("What is your grade: \(viewModel.selectedGrade ?? "Not selected")")
                    .font(.headline)
                
                Menu {
                    ForEach(viewModel.grades, id: \.self) { grade in
                        Button(grade, action: { viewModel.selectGrade(grade) })
                    }
                } label: {
                    Label("Select", systemImage: "chevron.down")
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .frame(minWidth: 120)
                }
            }
            
            // Subject Selection
            if let selectedGrade = viewModel.selectedGrade {
                HStack {
                    Text("Choose subject: \(viewModel.selectedSubject ?? "Not selected")")
                        .font(.headline)
                    
                    Menu {
                        ForEach(viewModel.subjects(for: selectedGrade), id: \.self) { subject in
                            Button(subject, action: { viewModel.selectSubject(subject) })
                        }
                    } label: {
                        Label("Select", systemImage: "chevron.down")
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
                    Text("Choose topic: \(viewModel.selectedTopic ?? "Not selected")")
                        .font(.headline)
                    
                    Menu {
                        ForEach(viewModel.topics(for: selectedSubject), id: \.self) { topic in
                            Button(topic, action: { viewModel.selectTopic(topic) })
                        }
                    } label: {
                        Label("Select", systemImage: "chevron.down")
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                            .frame(minWidth: 120)
                    }
                }
            }
            Button(action: {
                isLoading = true // Start loading
                                Task {
                                    let result = await viewModel.generateStudyTips()
                                    
                                    switch result {
                                    case .success(let message):
                                        // Parse message into an array of tips
                                        if let studyTips = try? JSONDecoder().decode(StudyTipsResponse.self, from: message.data(using: .utf8)!) {
                                            tips = studyTips.tips
                                        }
                                    case .failure(let error):
                                        alertMessage = "Failed to create study plan: \(error.localizedDescription)"
                                        showAlert = true
                                    }
                                    isLoading = false // End loading
                                }
            }) {
                Text("Generate Tips")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                Task {
                    await viewModel.loadDataSubjectTopics()
                }
            }
            // Show loading indicator while generating tips
                        if isLoading {
                            ProgressView("Loading...")
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .padding()
                        }
            // Display grade, subject, and topic information only after tips are generated
                        if !tips.isEmpty,
                           let selectedGrade = viewModel.selectedGrade,
                           let selectedSubject = viewModel.selectedSubject,
                           let selectedTopic = viewModel.selectedTopic {
                            Text("Here are tips for Grade: \(selectedGrade), Subject: \(selectedSubject), Topic: \(selectedTopic)")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.top)
                        }
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top) {
                            Text("•") // Bullet point
                                .font(.title)
                            Text(tip)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
    }
}

// Define a response model to parse the JSON
struct StudyTipsResponse: Codable {
    let grade: String
    let subject: String
    let tips: [String]
}

// Preview
struct StudyTipsView_Previews: PreviewProvider {
    static var previews: some View {
        StudyTipsView()
    }
}
