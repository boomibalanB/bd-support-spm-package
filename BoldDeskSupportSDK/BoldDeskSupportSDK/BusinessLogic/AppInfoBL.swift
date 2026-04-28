import Foundation

final class AppInfoBL {
    private let apiService = APIService()
    
    func getGeneralSetting(sdkId: String) async throws -> APIResponse {
        let encodedId = sdkId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sdkId
        let endpointURL = "/mobile_app/\(encodedId)"
        
        let response = try await apiService.sendAsync(
            endpointURL: endpointURL,
            httpMethod: "GET",
            baseURL: AppConstant.baseUrl
        )
        return response
    }
    
    
    func getUserInfo() async throws -> APIResponse {
        let endpointURL = "/profile"
        let res = try await apiService.sendAsync(
            endpointURL: endpointURL,
            httpMethod: "GET",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
    
    func getTimeZones() async throws -> APIResponse {
        let endpointURL = "/support/timezones"
        
        let res = try await apiService.sendAsync(
            endpointURL: endpointURL,
            httpMethod: "GET",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
}
