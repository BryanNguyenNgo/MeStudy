
import Foundation

import SwiftUI

class OfflineMode: ObservableObject {
    @Published var mode: Bool = false // Use a boolean for offline mode
}

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
    func loadOfflineMode() async -> Bool {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return false // Return false if plist is not found or parsing fails
        }

        if let isOfflineModeString = plist["OFFLINE_MODE"] as? String {
            // Convert the string to Bool based on the value
            return isOfflineModeString.uppercased() == "YES"
        }

        return false // Return false if the key is missing or invalid
    }



}
