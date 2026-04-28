import UIKit

class LoginBL {
    let apiService = APIService()

    func initializeSDK(appID: String, brandUrl: String) async throws
        -> APIResponse
    {

        let encodedAppId = appID.iosURLEncoded()

        let res = try await apiService.sendAsync(
            endpointURL:
                "/mobile_app?appId=\(encodedAppId)&brandUrl=\(brandUrl)",
            httpMethod: "GET",
            baseURL: AppConstant.baseUrl
        )
        var isSuccess = false
        if let dataDict = res.data as? [String: Any] {
            isSuccess = dataDict["success"] as? Bool ?? false
        }
        NetworkLogger.log(
            isSuccess
                ? ResourceManager.localized("appValidText", comment: "")
                : ResourceManager.localized("appNotValidText", comment: ""),
            level: .info
        )
        return res
    }

    func loginJWT(
        jwtToken: String
    ) async throws -> APIResponse {
        let payload: [String: String] = [
            "appId": AppConstant.appId,
            "jwtToken": jwtToken,
        ]
        let jsonData = try JSONEncoder().encode(payload)
        let res = try await apiService.sendAsync(
            endpointURL: "https://\(AppConstant.brandURl)/id/SDK/JWT",
            httpMethod: "POST",
            baseURL: "",
            body: jsonData
        )
        return res
    }

    func setFCMRegistrationToken(deviceToken: String) async throws
        -> APIResponse
    {
        let payload: [String: Any] = await [
            "platformId": 2,
            "deviceToken": deviceToken,
            "appId": AppConstant.appId,
            "additionalConfig": [
                "deviceName": UIDevice.current.name
            ],
            "mobileSdkId": AppConstant.mobileSDKId,
        ]
        let jsonData = try JSONSerialization.data(
            withJSONObject: payload,
            options: []
        )
        let res = try await apiService.sendAsync(
            endpointURL: "/mobile_app/device_token",
            httpMethod: "POST",
            baseURL: AppConstant.baseUrl,
            body: jsonData
        )
        return res
    }

    func deleteFCMRegistrationToken() async throws -> APIResponse {
        let res = try await apiService.sendAsync(
            endpointURL:
                "/mobile_app/device_token?deviceToken=\(AppConstant.deviceToken)",
            httpMethod: "DELETE",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
}

extension String {
    func iosURLEncoded() -> String {
        return
            self
            .replacingOccurrences(of: " ", with: "+")
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            .replacingOccurrences(of: "+", with: "%2B")
    }
}
