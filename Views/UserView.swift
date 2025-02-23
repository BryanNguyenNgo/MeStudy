import SwiftUI

struct UserView: View {
    @EnvironmentObject var userSession: UserSession
    @State private var name: String = "usertest"
    @State private var email: String = "usertest@gmail.com"
    @State private var grade: String = "10"  // Ensure this reflects the grade

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @ObservedObject var viewModel: UserViewModel
    var body: some View {
        VStack(spacing: 20) {
            // Display user information if available
            if let user = userSession.currentUser {
                Text("Welcome, \(user.name)")
            } else {
                Text("No user logged in")
            }
            
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Name input field
            TextField("Enter your name", text: $name)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.words)
            
            // Email input field
            TextField("Enter your email", text: $email)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
            
            // Grade Selection
            HStack {
                Text("What is your grade: \(grade)")
                    .font(.headline)
                
                Menu {
                    ForEach(viewModel.grades, id: \.self) { gradeOption in
                        Button(gradeOption, action: {
                            grade = gradeOption // Directly update the state variable
                            viewModel.selectGrade(gradeOption)  // Update ViewModel's grade
                        })
                    }
                } label: {
                    Label("Select", systemImage: "chevron.down")
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        .frame(minWidth: 120)
                }
            }
            
            // Save button to submit user data
            Button(action: {
                Task {
                    let result = await viewModel.createUser(id: UUID().uuidString, name: name, email: email, grade: grade)

                    switch result {
                    case .success(let id):
                        if !id.isEmpty { // ✅ Ensure `id` is not empty
                            alertMessage = "User ID \(id) is inserted successfully!" // ✅ Use `id`, not `name`
                            showAlert = true
                        }
                    case .failure:
                        alertMessage = "Failed to insert user ID."
                        showAlert = true
                    }
                }
            }) {
                Text("Save")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Success"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }

            Spacer()
        }
        .padding()
        .onAppear {
            Task {
                await viewModel.loadDataSubjectTopics()
            }
        }
    }
}
