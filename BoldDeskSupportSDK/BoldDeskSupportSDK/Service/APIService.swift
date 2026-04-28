//import Foundation

import Foundation
class APIService {
    static let shared = APIService()
    
    func sendAsync(
        endpointURL: String,
        httpMethod: String,
        object: Any? = nil,
        cancellationToken: NetworkCancellationToken? = nil,
        baseURL: String = "",
        customBaseURL: String? = nil,
        isFromRefresh: Bool = false,
        authToken: String? = nil,
        body: Data? = nil,
        contentType: String = "application/json"
    ) async throws -> APIResponse {
        
        var apiResponse = APIResponse()
        
        guard let url = URL(string: baseURL + endpointURL) else {
            apiResponse.statusCode = 408
            apiResponse.isSuccess = false
            apiResponse.data = ["message": "Invalid URL"]
            let payloadString = body != nil ? String(data: body!, encoding: .utf8) ?? "Invalid Body" : "nil"
            // 🔴 Log Error
            NetworkLogger.log("""
                        URL: \(baseURL + endpointURL)
                        Method: \(httpMethod)
                        Status: 408
                        Payload: \(payloadString))
                        Error: Invalid URL
                        """, level: .error)
            
            return apiResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(AppConstant.authToken)", forHTTPHeaderField: "Authorization")
        request.setValue(AppConstant.appId, forHTTPHeaderField: "AppID")
        request.httpBody = body
        request.setValue(AppConstant.applicationInfo, forHTTPHeaderField: "User-Agent")
        request.setValue(AppConstant.appId, forHTTPHeaderField: "AppID")
        
        do {
            let isNetworkAvailable = InternetConnectionListener.shared.isConnected
            guard isNetworkAvailable else {
                apiResponse.statusCode = 408
                apiResponse.isSuccess = false
                apiResponse.data = ["message": "No internet connection"]
                                
                // 🔴 Log Error
                NetworkLogger.log("""
                            URL: \(url.absoluteString)
                            Method: \(httpMethod)
                            Status: 408
                            Error: No internet connection
                            """, level: .error)
                
                return apiResponse
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            apiResponse.statusCode = httpResponse.statusCode
            apiResponse.isSuccess = (200...299).contains(httpResponse.statusCode)
            let responseString = String(data: data, encoding: .utf8) ?? ""
            let payloadString = body != nil ? String(data: body!, encoding: .utf8) ?? "Invalid Body" : "nil"
            // 🟢 Log Response
                NetworkLogger.log("""
                            URL: \(url.absoluteString)
                            Method: \(httpMethod)
                            Status: \(httpResponse.statusCode)
                            Response: \(responseString)
                            Payload: \(payloadString)
                            """, level: apiResponse.isSuccess ? .response : .error)
            
            // Parse data as JSON dictionary or raw data
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                apiResponse.data = json
            } else {
                apiResponse.data = ["raw": String(data: data, encoding: .utf8) ?? ""]
            }
            
            return apiResponse
            
        } catch let error as URLError where error.code == .timedOut {
            apiResponse.statusCode = 408
            apiResponse.isSuccess = false
            apiResponse.data = ["message": "Request timed out"]
            let payloadString = body != nil ? String(data: body!, encoding: .utf8) ?? "Invalid Body" : "nil"
            // 🔴 Log Error
            NetworkLogger.log("""
                        URL: \(url.absoluteString)
                        Method: \(httpMethod)
                        Status: 408
                        Payload: \(payloadString)
                        Error: Request timed out
                        """, level: .error)
            
            return apiResponse
        } catch {
            apiResponse.statusCode = 500
            apiResponse.isSuccess = false
            apiResponse.data = ["message": error.localizedDescription]
            let payloadString = body != nil ? String(data: body!, encoding: .utf8) ?? "Invalid Body" : "nil"
            // 🔴 Log Error
            NetworkLogger.log("""
                        URL: \(url.absoluteString)
                        Method: \(httpMethod)
                        Status: 500
                        Payload: \(payloadString)
                        Error: \(error.localizedDescription)
                        """, level: .error)
            
            return apiResponse
        }
    }
}

final class NetworkCancellationToken {
    private var anyTask: CancellableTask?
    
    func setTask<T>(_ task: Task<T, any Error>) {
        anyTask = CancellableTaskWrapper(task)
    }
    
    func cancel() {
        anyTask?.cancel()
    }
    
    private class CancellableTaskWrapper<T>: CancellableTask {
        private let task: Task<T, any Error>
        
        init(_ task: Task<T, any Error>) {
            self.task = task
        }
        
        func cancel() {
            task.cancel()
        }
    }
    
    private protocol CancellableTask {
        func cancel()
    }
}
