import Foundation

class StringUtils {
    static let shared = StringUtils()

    private init() {} // Prevents initialization outside of the class
    
    enum CleanJSONError: Error {
        case invalidDataConversion
    }

    func cleanJSONString(from data: String) async throws -> Data {
        let dataCleaned = data.replacingOccurrences(of: "json", with: "", options: .caseInsensitive, range: nil)
        
        guard let jsonData = dataCleaned.data(using: .utf8) else {
            throw CleanJSONError.invalidDataConversion
        }
        
        return jsonData
    }

}
