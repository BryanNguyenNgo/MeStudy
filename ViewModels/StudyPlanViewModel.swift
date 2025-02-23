import Foundation
import Combine
import SwiftUI

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
    @AppStorage("offlineMode") private var offlineMode: Bool = false
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
            if let dataString = await LocalJSONDataManager.shared.loadDataFromJSONFile(fileName: "Data_SubjectTopics", fileExtension: "json"),
               let data = dataString.data(using: .utf8) { // Convert String to Data
               
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
        
        let fileName = LocalJSONDataManager.shared.generateValidFileName(moduleName: "lessonplan", grade: grade, subject: subject, topic: topic)
        
        var generatedPlanResult: Result<String, NSError> = .failure(NSError()) // Initialize with failure by default
        var id: String = UUID().uuidString // Initialize id here
        
        print("UserId at generateStudyPlan: \(userId)")
        
        do {
            if offlineMode {
                // Retrieve from JSON file
                if let result = await LocalJSONDataManager.shared.loadDataFromJSONFile(fileName: fileName, fileExtension: "json") {
                    print("✅ Loaded Lesson Plan from offline JSON")
                    
                    // Assuming `result` is a string, you need to convert it into Data
                    if let data = result.data(using: .utf8) {
                        let decoder = JSONDecoder()
                        do {
                            // Decode the data into a LessonPlan object
                            let lessonPlan = try decoder.decode(LessonPlan.self, from: data)
                            
                            // Print out the decoded values
                            print("Study Plan for: \(lessonPlan.studyPlanId)")
                            id = lessonPlan.studyPlanId // Use the id from the decoded object
                            generatedPlanResult = .success(result) // Pass the success result to generatedPlanResult
                        } catch {
                            // Handle decoding error
                            print("Error decoding lesson plan: \(error.localizedDescription)")
                            let decodingError = NSError(domain: "StudyPlanViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode lesson plan."])
                            generatedPlanResult = .failure(decodingError)
                        }
                    } else {
                        let error = NSError(domain: "StudyPlanViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data."])
                        generatedPlanResult = .failure(error)
                    }
                } else {
                    let error = NSError(domain: "StudyPlanViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Offline mode enabled, but no saved data found."])
                    generatedPlanResult = .failure(error)
                }
            } else {
                // 1. Create StudyPlan object
                print("Preparing new StudyPlan for generation.")
            }
            
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

            // 2. Save study plan to database
            let saveResult = await studyPlan.saveToDatabase()
            switch saveResult {
            case .success(let studyPlanInsertedId):
                print("StudyPlan saved successfully: \(studyPlanInsertedId)")

                if !offlineMode {
                    // 4. Generate study plan
                    generatedPlanResult = await studyPlan.generatePlan()
                }

                switch generatedPlanResult {
                case .success(var generatedPlanJson):
                    print("Generated Plan JSON: \(generatedPlanJson)")
                    
                    // Save for offline use
                    do {
                        try await LocalJSONDataManager.shared.saveJSON(data: generatedPlanJson, fileName: fileName)
                        print("✅ LessonPlan saved for offline mode: \(fileName)")
                    } catch {
                        print("❌ Failed to save LessonPlan: \(error.localizedDescription)")
                        return .failure(error as NSError)
                    }

                    // 5. Convert response to LessonPlan object
                    let lessonPlanResult = await LessonPlan.shared.decodeLessonPlan(from: generatedPlanJson)

                    switch lessonPlanResult {
                    case .success(let lessonPlanOptional):
                        guard let lessonPlan = lessonPlanOptional else {
                            let error = NSError(domain: "LessonPlanError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Decoded lesson plan is nil"])
                            return .failure(error)
                        }

                        // 6. Save the generated lesson plan to the database
                        print("decodeLessonPlan success")
                        print("lessonPlan.studyPlanId: \(lessonPlan.studyPlanId)")
                        let saveLessonResult = await LessonPlan.shared.saveToDatabase(from: lessonPlan)
                        switch saveLessonResult {
                        case .success(let studyPlanId):
                            // 7. Update UI and return success
                            print("saveToDatabase success: \(studyPlanId)")
                            return .success(studyPlanId)

                        case .failure(let error):
                            return .failure(error)
                        }

                    case .failure(let error):
                        return .failure(error)
                    }

                case .failure(let error):
                    if let nsError = error as? NSError {
                        return .failure(nsError)
                    } else {
                        let customNSError = NSError(domain: "StudyPlanError", code: 500, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                        return .failure(customNSError)
                    }

                }

            case .failure(let error):
                print("Failed to save study plan: \(error.localizedDescription)")
                if let nsError = error as? NSError {
                    return .failure(nsError)
                } else {
                    let customNSError = NSError(domain: "StudyPlanError", code: 500, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                    return .failure(customNSError)
                }
            }

        } catch {
            // Handle any errors that might have been thrown during the process
            print("Error during study plan generation: \(error.localizedDescription)")
            if let nsError = error as? NSError {
                return .failure(nsError)
            } else {
                let customNSError = NSError(domain: "StudyPlanError", code: 500, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                return .failure(customNSError)
            }
        }
    }
//    func generateStudyPlan(
//        userId: String,
//        grade: String,
//        subject: String,
//        topic: String,
//        duration: Int,
//        commitment: Int
//    ) async -> Result<String, NSError> {
//        
//        // Start loading state
//        setLoadingState(true)
//        
//        defer { setLoadingState(false) }
//        
//        let fileName = generateFileName(grade: grade, subject: subject, topic: topic)
//        
//        var generatedPlanResult: Result<String, NSError> = .failure(NSError())
//        
//        do {
//            if offlineMode {
//                // Load offline plan
//                let generatedPlanResult = await loadOfflinePlan(fileName: fileName)
//                
//                switch generatedPlanResult {
//                case .success(let planData):
//                    do {
//                        // Attempt to decode the lesson plan
//                        if let studyPlan = try decodeLessonPlan(from: planData, userId: userId,grade: grade,
//                                                                subject: subject,
//                                                                topic: topic,
//                                                                duration: duration,
//                                                                commitment: commitment) {
//                            // Save to database
//                            await saveStudyPlan(studyPlan)
//                            return .success("Study Plan successfully generated.") // Return success message
//                        }
//                    } catch {
//                        print("Error decoding lesson plan: \(error)")
//                        return .failure(createNSError(from: error))
//                    }
//                    
//                case .failure(let error):
//                    print("Failed to load offline plan: \(error)")
//                    return .failure(error)
//                }
//                
//            } else {
//                // Generate a new study plan
//                let studyPlan = try await createStudyPlan(userId: userId, grade: grade, subject: subject, topic: topic, duration: duration, commitment: commitment)
//                generatedPlanResult = await generateAndSavePlan(studyPlan: studyPlan, fileName: fileName)
//                
//                
//            }
//            
//            // Handle the result from plan generation
//            print("handleGeneratedPlanResult here")
//            return try await handleGeneratedPlanResult(result: generatedPlanResult)
//            
//        } catch {
//            return .failure(createNSError(from: error))
//        }
//    }
    // MARK: - Helper Functions
    // Helper to decode LessonPlan from JSON string
    func decodeLessonPlan(from jsonString: String,  userId: String,
                          grade: String,
                          subject: String,
                          topic: String,
                          duration: Int,
                          commitment: Int) throws -> StudyPlan? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        
        let decoder = JSONDecoder()
        let lessonPlan = try decoder.decode(LessonPlan.self, from: data)
        
        return StudyPlan(
            id: lessonPlan.studyPlanId,
            userId: userId,
            grade: grade,
            subject: subject,
            topic: topic,
            studyDuration: duration,
            studyFrequency: commitment,
            status: StudyPlanStatusType.notStarted.rawValue,
            scorePercentage: 0
        )
    }
    func saveStudyPlan(_ studyPlan: StudyPlan) async {
        let saveResult = await studyPlan.saveToDatabase()
        // Handle the result if needed (e.g., error handling, success confirmation)
    }
    private func setLoadingState(_ isLoading: Bool) {
        DispatchQueue.main.async {
            self.isLoading = isLoading
            self.errorMessage = nil
        }
    }

    private func generateFileName(grade: String, subject: String, topic: String) -> String {
        return LocalJSONDataManager.shared.generateValidFileName(moduleName: "lessonplan", grade: grade, subject: subject, topic: topic)
    }

    private func loadOfflinePlan(fileName: String) async -> Result<String, NSError> {
        guard let result = await LocalJSONDataManager.shared.loadDataFromJSONFile(fileName: fileName, fileExtension: "json") else {
            return .failure(createNSError(message: "Offline mode enabled, but no saved data found."))
        }
        
        return await decodeLessonPlan(from: result)
    }

    private func decodeLessonPlan(from result: String) async -> Result<String, NSError> {
        if let data = result.data(using: .utf8) {
            let decoder = JSONDecoder()
            do {
                let lessonPlan = try decoder.decode(LessonPlan.self, from: data)
                print("Study Plan for: \(lessonPlan.studyPlanId)")
                return .success(result)
            } catch {
                return .failure(createNSError(message: "Failed to decode lesson plan."))
            }
        } else {
            return .failure(createNSError(message: "Failed to convert string to data."))
        }
    }

    private func createStudyPlan(userId: String, grade: String, subject: String, topic: String, duration: Int, commitment: Int) async throws -> StudyPlan {
        let id = UUID().uuidString
        print("Preparing new StudyPlan for generation.")
        
        return StudyPlan(
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
    }

    private func generateAndSavePlan(studyPlan: StudyPlan, fileName: String) async -> Result<String, NSError> {
        let saveResult = await studyPlan.saveToDatabase()
        
        switch saveResult {
        case .success(let studyPlanInsertedId):
            print("StudyPlan saved successfully: \(studyPlanInsertedId)")
            // If offline mode is enabled, return early with the study plan ID
            guard !offlineMode else { return .success(studyPlanInsertedId) }
            
            let result = await studyPlan.generatePlan()
            switch result {
            case .success(let jsonString):
                // Save for offline use
                do {
                    try await LocalJSONDataManager.shared.saveJSON(data: jsonString, fileName: fileName)
                    print("✅ Tips saved for offline mode: \(fileName)")
                } catch {
                    print("❌ Failed to save quiz: \(error.localizedDescription)")
                    return .failure(error as NSError)
                }
                // Return success result with the study plan jsonString
                return .success(jsonString)
                
            case .failure(let error):
                return .failure(createNSError(from: error))
            }
            
        case .failure(let error):
            return .failure(createNSError(from: error))
        }
    }


    private func handleGeneratedPlanResult(result: Result<String, NSError>) async throws -> Result<String, NSError> {
        switch result {
        case .success(var generatedPlanJson):
            print("Generated Plan JSON at handleGeneratedPlanResult: \(generatedPlanJson)")
            
            let lessonPlanResult = await LessonPlan.shared.decodeLessonPlan(from: generatedPlanJson)
            
            switch lessonPlanResult {
            case .success(let lessonPlanOptional):
                guard let lessonPlan = lessonPlanOptional else {
                    return .failure(createNSError(message: "Decoded lesson plan is nil"))
                }
                
                return await saveLessonPlan(lessonPlan: lessonPlan)
                
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }

    private func saveLessonPlan(lessonPlan: LessonPlan) async -> Result<String, NSError> {
        let saveLessonResult = await LessonPlan.shared.saveToDatabase(from: lessonPlan)
        switch saveLessonResult {
        case .success(let studyPlanId):
            print("saveLessonPlan called saveToDatabase success: \(studyPlanId)")
            return .success(studyPlanId)
        case .failure(let error):
            return .failure(error)
        }
    }

    private func createNSError(from error: Error) -> NSError {
        return NSError(domain: "StudyPlanError", code: 500, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
    }

    private func createNSError(message: String) -> NSError {
        return NSError(domain: "StudyPlanError", code: 500, userInfo: [NSLocalizedDescriptionKey: message])
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
        
    }


}
