import Foundation
import Combine

// Structs to decode the JSON
struct GradeData: Codable {
    let grade: Int
    let subjects: [SubjectData]
}

struct SubjectData: Codable {
    let subject: String
    let topics: [String]
}

class StudyPlanViewModel: ObservableObject {
    @Published var selectedGrade: String? = nil  // Make this optional
    @Published var selectedSubject: String? = nil  // Make this optional
    @Published var selectedTopic: String? = nil  // Make this optional
    
    @Published var selectedDuration: String = ""
    @Published var selectedCommitment: String = ""
    
    @Published var userInput: String = ""
    @Published var generatedPlan: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    @Published var studyPlans: [StudyPlan] = [] // Store study plans for the user

    // For UI display
    @Published var grades: [String] = []
    @Published var subjects: [String: [String]] = [:]
    @Published var topics: [String: [String]] = [:]
    
    // For ScannerView
    @Published var recognizedText: String = ""
    
    // Load data from JSON for grades, subjects and topics
    func loadDataSubjectTopics() async {
        do {
            // Load JSON data from a file
            if let data = await LocalJSONDataManager.shared.loadDataFromJSONFile(fileName: "Data_SubjectTopics", fileExtension: "json") {
                let decoder = JSONDecoder()
                
                // Decode the data into the appropriate model
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
            } else {
                print("Failed to load JSON file: Data_SubjectTopics.json")
            }
        } catch {
            print("Error decoding JSON: \(error.localizedDescription)")
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

    // Method to create a new StudyPlan object and save it to the database
    func generateStudyPlan(
        userId: String,
        grade: String,
        subject: String,
        topic: String,
        duration: Int,
        commitment: Int
    ) async -> Result<String, NSError> {
        
        // Indicate loading
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
            print("UserId at generateStudyPlan: \(userId)")
            // Create StudyPlan object
            let id = UUID().uuidString
            print("Prepared StudyPlan at generateStudyPlan id: \(id)")
            let studyPlan = StudyPlan(
                id: id,
                userId: userId,
                grade: grade,
                subject: subject,
                topic: topic,
                studyDuration: duration,
                studyFrequency: commitment,
                status: StudyPlanStatusType.notStarted.rawValue,
                scorePercentage: 0
            )
            
            // 1. Save study plan to database
            let saveResult = await studyPlan.saveToDatabase()
            switch saveResult {
            case .success(let studyPlanInsertedId):
                print("StudyPlan saved successful \(studyPlanInsertedId)")
                
                
                // 2. Generate study plan
                let generatedPlanResult = await studyPlan.generatePlan()
                
                switch generatedPlanResult {
                case .success(var generatedPlanJson): // Make it mutable
                    print("Generated Plan JSON: \(generatedPlanJson)")
                    
                   
                    
                    // 3. Convert response to LessonPlan object
                    let lessonPlanResult = await LessonPlan.shared.decodeLessonPlan(from: generatedPlanJson)
                    
                    switch lessonPlanResult {
                    case .success(let lessonPlanOptional):
                        guard let lessonPlan = lessonPlanOptional else {
                            let error = NSError(domain: "LessonPlanError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Decoded lesson plan is nil"])
                            return .failure(error)
                        }

                        // 4. Save the generated lesson plan to the database
                        print("decodeLessonPlan success")
                        print("lessonPlan.studyPlanId: \(lessonPlan.studyPlanId)")
                        let saveLessonResult = await LessonPlan.shared.saveToDatabase(from: lessonPlan)
                        switch saveLessonResult {
                        case .success(let studyPlanId):
                            // 5. Update UI and return success
                            
//                            DispatchQueue.main.async {
//                                self.generatedPlan = "Study Plan: \(grade), \(subject), \(duration) hours, \(commitment) times per week"
//                            }
                            print("saveToDatabase success: \(studyPlanId)")
                            return .success(studyPlanId)
                            
                        case .failure(let error):
                            return .failure(error)
                        }
                        
                    case .failure(let error):
                        return .failure(error)
                    }
                    
                case .failure(let error):
                    return .failure(error)
                }
                
            case .failure(let error):
                print("Failed to save study plan: \(error.localizedDescription)")
                return .failure(error)
            }
            
        
    }

    @MainActor
    func getStudyPlans(userId: String) async {
        self.isLoading = true
        
        // Create a dummy study plan for now (replace with real fetch)
        let plans = await fetchStudyPlans(userId: userId)
        
        self.studyPlans = plans
        self.isLoading = false
    }
    
    // Method that returns study plans (this can be modified to fetch data from a database or API)
    @MainActor
    private func fetchStudyPlans(userId: String) async -> [StudyPlan] {
        // Create a new StudyPlan object
        let studyPlan = StudyPlan(id: "", userId: userId, grade: "", subject: "", topic: "", studyDuration: 0, studyFrequency: 0, status: "", scorePercentage:0)
        
        // Assuming you are fetching real study plans here
        let studyPlans = await studyPlan.getStudyPlans(userId: userId)
        print("Fetched studyPlans: \(studyPlans)")
        
        return studyPlans
    }
    // for scannerView
    func extractStudyPlan(
        recognizedText: String
    ) async -> Result<StudyPlanExtracted?, NSError> {
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            // Generate study plan
            let generatedResult = await StudyPlan.shared.extractStudyPlan(recognizedText: recognizedText)
            
            switch generatedResult {
            case .success(let generatedJson):
                print("Generated Plan JSON: \(generatedJson)")
                
                // Decode the study plan
                let decodedResult = await StudyPlan.shared.decodeStudyPlanExtracted(from: generatedJson)
                
                switch decodedResult {
                case .success(let studyPlan):
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    print("Decoded Study Plan:\(decodedResult)")
                    return .success(studyPlan)
                    
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return .failure(error)
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return .failure(error)
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error: \(error.localizedDescription)"
            }
            
            let nsError = NSError(domain: "StudyPlanError", code: 500, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
            return .failure(nsError)
        }
    }


}
