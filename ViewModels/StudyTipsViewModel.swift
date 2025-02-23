import Foundation

class StudyTipsViewModel: ObservableObject {
    @Published var selectedGrade: String? = nil  // Make this optional
    @Published var selectedSubject: String? = nil  // Make this optional
    @Published var selectedTopic: String? = nil  // Make this optional
    
    // For UI display
    @Published var grades: [String] = []
    @Published var subjects: [String: [String]] = [:]
    @Published var topics: [String: [String]] = [:]
    
    // Load data from JSON for subjects and topics
    func loadDataSubjectTopics() async {
        // Load JSON data from a file
        guard let data = await LocalJSONDataManager.shared.loadDataFromJSONFile(fileName: "Data_SubjectTopics", fileExtension: "json") else {
            print("Failed to load data from file.")
            return
        }
        
        let decoder = JSONDecoder()
        
        do {
            // Attempt to decode the data
            let decodedData = try decoder.decode([GradeData].self, from: data)
            
            grades = decodedData.map { "Grade \($0.grade)" }
            
            // Populate subjects and topics
            for gradeData in decodedData {
                let gradeKey = "Grade \(gradeData.grade)"
                subjects[gradeKey] = gradeData.subjects.map { $0.subject }
                
                for subject in gradeData.subjects {
                    topics["\(gradeKey)-\(subject.subject)"] = subject.topics
                }
            }
        } catch {
            print("Failed to decode data: \(error)")
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
    func generateStudyTips() async -> Result<String, NSError> {
        let isOfflineMode = await AppConfig.shared.loadOfflineMode()
        
//        print("Offline Mode: \(isOfflineMode). Generate tips: ")
//        if(isOfflineMode){
//            retrieveFromLocalJSONFile()
//        }
        
        // Ensure that selectedGrade and selectedSubject are not nil
        guard let grade = selectedGrade, let subject = selectedSubject else {
            let error = NSError(domain: "StudyTipsViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Grade or Subject is not selected"])
            return .failure(error)
        }
        
        // Instantiate the StudyTips object
        // Force unwrap the optional values (only if you're sure they won't be nil)
            let studyTips = StudyTips(
                grade: self.selectedGrade!,  // Force unwrap
                subject: self.selectedSubject!,  // Force unwrap
                topic: self.selectedTopic!,  // Force unwrap
                tips: []
            )
        
        // Fetch the study tips
        let tipsResult = await studyTips.generateStudyTips()
        
        // Handle the result of the study tips generation
        switch tipsResult {
        case .success(let tips):
            // Process the generated tips (you could return them or store them)
            return .success(tips)
        case .failure(let error):
            // Handle error if tips generation failed
            print("Failed to generate study tips: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}

