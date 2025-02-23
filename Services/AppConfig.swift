
import Foundation

class AppConfig {
    static let shared = AppConfig()
    
    let apiUrl = "https://api.openai.com/v1/chat/completions"
    
    private init() {} // Private initializer ensures it's a singleton
    
    func loadApiKey() async -> String? {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let apiKey = plist["OPENAI_API_KEY"] as? String else {
            return nil
        }
        return apiKey
    }
    func loadOfflineMode() async -> Bool? {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let isOfflineMode = plist["OFFLINE_MODE"] as? Bool else {
            return nil
        }
        return isOfflineMode
    }
}
