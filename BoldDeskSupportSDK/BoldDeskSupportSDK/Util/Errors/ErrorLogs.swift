import Foundation
internal import Sentry

struct ErrorLogs {

    static func logErrors(
        data: Any?,
        exceptionPage: String = "",
        isCatchError: Bool = false,
        statusCode: Int? = nil,
        stackTrace: String? = nil
    ) {
        if isCatchError {
            handleCaughtError(data, exceptionPage: exceptionPage)
        } else {
            handleAPIError(data)
        }
    }
}

// MARK: - Private Helpers
extension ErrorLogs {

    fileprivate static func handleAPIError(_ data: Any?) {
        guard let data = data else {
            showToast(ResourceManager.localized("unknownError", comment: ""))
            return
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)

            // 1️⃣ Try to extract custom `errorMessage`
            if let json = try JSONSerialization.jsonObject(with: jsonData)
                as? [String: Any],
                let errorMessage = (json["errors"] as? [[String: Any]])?.first?[
                    "errorMessage"
                ] as? String
            {
                showToast(errorMessage)
                if AppConstant.environment != "development" {
                    captureSentryMessage(errorMessage)
                }
                return
            }

            // 2️⃣ Try decoding `ExceptionMessage`
            let decoded = try JSONDecoder().decode(
                ExceptionMessage.self,
                from: jsonData
            )
            if let message = decoded.message,
                message.lowercased() != "cancelled"
            {
                let msg =
                    message.isEmpty
                    ? ResourceManager.localized("someThingWentWrongText")
                    : message
                showToast(msg)
                if AppConstant.environment != "development" {
                    captureSentryMessage(msg)
                }
            }

        } catch {
            showToast(error.localizedDescription)
        }
    }

    fileprivate static func handleCaughtError(
        _ data: Any?,
        exceptionPage: String?
    ) {
        showToast(ResourceManager.localized("someThingWentWrongText"))

        guard
            let error = data as? Error,
            AppConstant.environment != "development"
        else { return }

        captureSentryError(error: error, exceptionPage: exceptionPage)
    }

    fileprivate static func showToast(_ message: String) {
        ToastManager.shared.show(message, type: .error)
    }
}

// MARK: - Sentry Logging
extension ErrorLogs {

    fileprivate static func captureSentryError(
        error: Error,
        exceptionPage: String?
    ) {
        DispatchQueue.main.async {
            configureSentryScope(exceptionPage: exceptionPage)
            SentrySDK.capture(error: error)
        }
    }

    fileprivate static func captureSentryMessage(_ message: String) {
        DispatchQueue.main.async {
            configureSentryScope()
            SentrySDK.capture(message: message)
        }
    }

    /// Applies all standard tags to Sentry scope
    fileprivate static func configureSentryScope(exceptionPage: String? = nil) {
        SentrySDK.configureScope { scope in
            scope.setTag(value: AppConstant.appId, key: "App ID")
            scope.setTag(value: AppConstant.brandURl, key: "BrandURL")
            scope.setTag(value: AppConstant.mobileSDKId, key: "SDKGuid")
            scope.setTag(
                value: AppConstant.clientAppName,
                key: "Integrated app name"
            )
            scope.setTag(value: AppConstant.deviceName, key: "Device name")
            scope.setTag(
                value: AppConstant.osVersion,
                key: "Device OS version"
            )
            scope.setTag(value: AppConstant.sdkVersion, key: "SDK version")
            scope.setTag(value: AppConstant.environment, key: "Environment")
        }
    }
}
