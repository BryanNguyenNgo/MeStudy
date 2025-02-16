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
        
    // Load data from JSON for grades, subjects and topics
    func loadDataSubjectTopics() async {
        // Load JSON data from a file
        if let url = Bundle.main.url(forResource: "Data_SubjectTopics", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            let decoder = JSONDecoder()
            if let decodedData = try? decoder.decode([GradeData].self, from: data) {
                grades = decodedData.map { "Grade \($0.grade)" }
                
                // Populate subjects and topics
                for gradeData in decodedData {
                    let gradeKey = "Grade \(gradeData.grade)"
                    subjects[gradeKey] = gradeData.subjects.map { $0.subject }
                    for subject in gradeData.subjects {
                        topics["\(gradeKey)-\(subject.subject)"] = subject.topics
                    }
                }
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
        
        do {
            print("UserId at generateStudyPlan: \(userId)")
            // Create StudyPlan object
            let studyPlan = StudyPlan(
                id: UUID().uuidString,
                userId: userId,
                grade: grade,
                subject: subject,
                topic: topic,
                studyDuration: duration,
                studyFrequency: commitment,
                status: StudyPlanStatusType.notStarted.rawValue
            )
            
            // 1. Save study plan to database
            let saveResult = await studyPlan.saveToDatabase()
            switch saveResult {
            case .success(let studyPlanInsertedId):
                print("Save successful? \(studyPlanInsertedId)")
                
                // Generate a unique lessonPlanStudyPlanId
                let lessonPlanStudyPlanId = UUID().uuidString
                
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
                        let saveLessonResult = await LessonPlan.shared.saveToDatabase(from: lessonPlan)
                        switch saveLessonResult {
                        case .success:
                            // 5. Update UI and return success
                            DispatchQueue.main.async {
                                self.generatedPlan = "Study Plan: \(grade), \(subject), \(duration) hours, \(commitment) times per week"
                            }
                            return .success(generatedPlanJson)
                            
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
            
        } catch {
            let nsError = NSError(domain: "StudyPlanError", code: 500, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
            
            DispatchQueue.main.async {
                self.errorMessage = "Error: \(error.localizedDescription)"
            }
            
            return .failure(nsError)
        }
    }

    // Your existing method for fetching study plans
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
        // For now, return hardcoded data for debugging
        // Create a new StudyPlan object
        let studyPlan = StudyPlan(id: "", userId: userId, grade: "", subject: "", topic: "", studyDuration: 0, studyFrequency: 0, status: "")
        
        // Assuming you are fetching real study plans here
        let studyPlans = try await studyPlan.getStudyPlans(userId: userId)
        print("Fetched studyPlans: \(studyPlans)")
        
        return studyPlans
    }
}
