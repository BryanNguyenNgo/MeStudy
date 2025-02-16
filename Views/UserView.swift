import SwiftUI

struct UserView: View {
    @EnvironmentObject var userSession: UserSession
    @State private var name: String = "user1"
    @State private var email: String = "user1@gmail.com"
    @State private var grade: String = ""
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @StateObject private var viewModel: UserViewModel
    
    init(userSession: UserSession) {
        // Ensure viewModel is initialized correctly with userSession
        _viewModel = StateObject(wrappedValue: UserViewModel(userSession: userSession))
    }
    
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
                Text("What is your grade: \(viewModel.selectedGrade ?? "Not selected")")
                    .font(.headline)
                
                Menu {
                    ForEach(viewModel.grades, id: \.self) { grade in
                        Button(grade, action: {
                            viewModel.selectGrade(grade)
                            self.grade = grade // Update `grade` when a selection is made
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
                    let result = await viewModel.createUser(name: name, email: email, grade: grade)

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
            })  {
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

struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        UserView(userSession: UserSession()) // Pass in a dummy UserSession
            .environmentObject(UserSession()) // Make sure the environment object is provided
    }
}
