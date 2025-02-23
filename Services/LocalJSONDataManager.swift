import Foundation

class LocalJSONDataManager {
    static let shared = LocalJSONDataManager()
    private init() {} // Prevents initialization outside of the class
    
    // Method to populateFileName
    func generateValidFileName(moduleName: String, grade: String, subject: String, topic: String) -> String {
        // Construct a valid file name, removing invalid characters
        let fileName = "\(moduleName)_\(grade)_\(subject)_\(topic)"
            .replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "", options: .regularExpression) // Remove invalid characters
        
        return fileName
    }

    // Load data from JSON for grades, subjects and topics
    func loadDataFromJSONFile(fileName: String, fileExtension: String) async -> String? {
        // Load JSON data from a file
        if let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
            do {
                let data = try Data(contentsOf: url)
                return String(data: data, encoding: .utf8)
            } catch {
                print("Failed to load JSON file: \(error.localizedDescription)")
                return nil
            }
        }
        return nil // Ensure the function always returns a value
    }

    /// Save JSON data to a file in the Documents directory
    func saveJSON(data: String, fileName: String) async throws {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        let fileURL = documentsURL.appendingPathComponent("\(fileName).json")

        // Convert String to Data and save
        if let jsonData = data.data(using: .utf8) {
            try jsonData.write(to: fileURL, options: .atomic)
            print("✅ JSON saved: \(fileURL.path)")
        } else {
            throw NSError(domain: "SaveJSONError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])
        }
    }

        
        /// Load JSON data from a file in the Documents directory
        func loadJSON(fileName: String) -> String? {
            let fileManager = FileManager.default
            do {
                let documentsURL = try fileManager.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
                let fileURL = documentsURL.appendingPathComponent("\(fileName).json")

                let data = try Data(contentsOf: fileURL)
                return String(data: data, encoding: .utf8)
            } catch {
                print("❌ Error loading JSON: \(error.localizedDescription)")
                return nil
            }
        }

        /// Delete a JSON file from the Documents directory
        func deleteJSON(fileName: String) {
            let fileManager = FileManager.default
            do {
                let documentsURL = try fileManager.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
                let fileURL = documentsURL.appendingPathComponent("\(fileName).json")

                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                    print("✅ JSON deleted: \(fileURL.path)")
                }
            } catch {
                print("❌ Error deleting JSON: \(error.localizedDescription)")
            }
        }

}
