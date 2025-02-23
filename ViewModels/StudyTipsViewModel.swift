import Foundation
import SwiftUI

class StudyTipsViewModel: ObservableObject {
    @AppStorage("offlineMode") private var offlineMode: Bool = false
    @Published var selectedGrade: String? = nil  // Make this optional
    @Published var selectedSubject: String? = nil  // Make this optional
    @Published var selectedTopic: String? = nil  // Make this optional
    
    // For UI display
    @Published var grades: [String] = []
    @Published var subjects: [String: [String]] = [:]
    @Published var topics: [String: [String]] = [:]
    
    // Load data from JSON for subjects and topics
    @MainActor
    func loadDataSubjectTopics() async {
        // Load JSON data from a file
        if let dataString = await LocalJSONDataManager.shared.loadDataFromJSONFile(fileName: "Data_SubjectTopics", fileExtension: "json"),
           let data = dataString.data(using: .utf8) { // Convert String to Data
            
            let decoder = JSONDecoder()
            
            do {
                // Attempt to decode the data
                let decodedData = try decoder.decode([GradeData].self, from: data)
                
                // Ensure UI updates happen on the main thread
                DispatchQueue.main.async {
                    self.grades = decodedData.map { "Grade \($0.grade)" }
                    
                    // Populate subjects and topics
                    for gradeData in decodedData {
                        let gradeKey = "Grade \(gradeData.grade)"
                        self.subjects[gradeKey] = gradeData.subjects.map { $0.subject }
                        
                        for subject in gradeData.subjects {
                            self.topics["\(gradeKey)-\(subject.subject)"] = subject.topics
                        }
                    }
                }
            } catch {
                print("Failed to decode data: \(error)")
            }
        }
    }

    func selectGrade(_ grade: String) {
        self.selectedGrade = grade
        self.selectedSubject = nil
        self.selectedTopic = nil
    }
        
    func selectSubject(_ subject: String) {
        self.selectedSubject = subject
        self.selectedTopic = nil
    }
        
    func selectTopic(_ topic: String) {
        self.selectedTopic = topic
    }
        
    func subjects(for grade: String) -> [String] {
        return subjects[grade] ?? []
    }
        
    func topics(for subject: String) -> [String] {
        guard let selectedGrade = selectedGrade else { return [] }
        return topics["\(selectedGrade)-\(subject)"] ?? []
    }
    

    // Method to generate study tips
    func generateStudyTips() async -> Result<String, Error> {
        let isOfflineMode = offlineMode
        // Ensure selectedGrade and selectedSubject are not nil
        guard let grade = selectedGrade, let subject = selectedSubject, let topic = selectedTopic else {
            let error = NSError(domain: "StudyTipsViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Grade or Subject is not selected"])
            return .failure(error)
        }
        // Construct a valid file name
        let fileName = LocalJSONDataManager.shared.generateValidFileName( moduleName: "studytips", grade: grade, subject: subject, topic: topic)
        
        if isOfflineMode {
            if let offlineTips = await LocalJSONDataManager.shared.loadDataFromJSONFile(fileName: fileName, fileExtension: "json") {
                print("✅ Loaded study tips from offline JSON")
                return .success(offlineTips)
            } else {
                let error = NSError(domain: "StudyTipsViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Offline mode enabled, but no saved data found."])
                return .failure(error)
            }
        }

        // Instantiate StudyTips
        let studyTips = StudyTips(
            grade: grade,
            subject: subject,
            topic: selectedTopic ?? "",
            tips: []
        )

        // Fetch study tips
        let tipsResult = await studyTips.generateStudyTips()

        switch tipsResult {
        case .success(let tips):
            // Save for offline use
            do {
                try await LocalJSONDataManager.shared.saveJSON(data: tips, fileName: fileName)
                print("✅ Tips saved for offline mode: \(fileName)")
            } catch {
                print("❌ Failed to save study tips: \(error.localizedDescription)")
                return .failure(error)
            }
            
            return .success(tips)
            
        case .failure(let error):
            print("❌ Failed to generate study tips: \(error.localizedDescription)")
            return .failure(error)
        }
    }

}

