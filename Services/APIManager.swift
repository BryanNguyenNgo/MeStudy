import Foundation

class APIManager {
    static let shared = APIManager()

    private init() {} // Prevents initialization outside of the class

    // Common method to make an API request to OpenAI
    func callOpenAIAPI(prompt: String) async -> Result<String, NSError> {
        // Load API key
        guard let apiKey = await AppConfig.shared.loadApiKey() else {
            return .failure(NSError(domain: "APIKeyError", code: 400, userInfo: [NSLocalizedDescriptionKey: "API Key not loaded"]))
        }
        
        // Ensure valid API URL
        let apiUrl = AppConfig.shared.apiUrl
        guard let url = URL(string: apiUrl) else {
            return .failure(NSError(domain: "InvalidURL", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"]))
        }
        
        // Prepare request payload
        let requestBody: [String: Any] = [
            "model": "o1-preview",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        // Create URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return .failure(NSError(domain: "EncodingError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request body"]))
        }
        
        // Perform API request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                return .failure(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Request failed with status code \(httpResponse.statusCode)"]))
            }
            
            // Parse JSON response
            guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let choices = jsonResponse["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let text = message["content"] as? String else {
                return .failure(NSError(domain: "InvalidResponse", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]))
            }
            
            return .success(text)
        } catch {
            return .failure(NSError(domain: "NetworkError", code: 500, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
        }
    }

}

