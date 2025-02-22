//
//  StudyPlanDetailView.swift
//  MeStudy
//
//  Created by Bryan Nguyen on 22/2/25.
//

import SwiftUI

struct StudyPlanDetailView: View {
    @EnvironmentObject var userSession: UserSession // Access the user from the environment
    @StateObject private var viewModel = StudyPlanViewModel()
    // ViewModel as a @StateObject
    @StateObject private var quizViewModel = QuizViewModel()
    @State private var goToQuizDetailView = false
    @State private var selectedQuiz: Quiz?  // Track the selected quiz

    var plan: StudyPlan
    var studyPlanId: String// Change from String to StudyPlan object

    var body: some View {
        VStack() {
            Text(plan.topic)
                .font(.largeTitle)
                .bold()

            Text(plan.grade)
                .font(.body)
                .foregroundColor(.secondary)
            Text(plan.subject)
                .font(.body)
                .foregroundColor(.secondary)
            Text("\(plan.studyFrequency) per week")
                .font(.body)
                .foregroundColor(.secondary)
            Text("\(plan.studyDuration) weeks")
                .font(.body)
                .foregroundColor(.secondary)
            Text("\(plan.status ?? "status")")
                .font(.body)
                .foregroundColor(.secondary)
            Text("\(plan.createdAt)")
                .font(.body)
                .foregroundColor(.secondary)

            Spacer()
            Button {
                goToQuizDetailView = true
            } label: {
                Text("Start Quiz")
            }

        }
        .padding()
        .navigationTitle("Details")
       .onAppear {
        Task {
            await quizViewModel.getQuizzes(studyPlanId: studyPlanId)
        }
    }
        .navigationDestination(isPresented: $goToQuizDetailView) {
            if let quiz = selectedQuiz {
                QuizDetailView(quiz: quiz)  // Navigate to the quiz detail view
            }
        }
    }
}

