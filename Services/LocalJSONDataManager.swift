import Foundation

class LocalJSONDataManager {
    static let shared = LocalJSONDataManager()
    private init() {} // Prevents initialization outside of the class
    // Load data from JSON for grades, subjects and topics
    func loadDataFromJSONFile(fileName: String, fileExtension: String) async -> Data? {
        // Load JSON data from a file
        if let url = Bundle.main.url(forResource: "Data_SubjectTopics", withExtension: fileExtension),
           let data = try? Data(contentsOf: url) {
            return data
        }
        return nil // Ensure the function always returns a value
    }

}
