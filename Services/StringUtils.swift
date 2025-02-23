import Foundation

class StringUtils {
    static func cleanJSONString(from data: String) -> String {
        return data.replacingOccurrences(of: "json", with: "", options: .caseInsensitive, range: nil)
    }
}
