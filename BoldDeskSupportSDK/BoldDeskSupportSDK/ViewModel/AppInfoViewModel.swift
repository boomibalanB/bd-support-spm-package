import Foundation

@MainActor
final class AppInfoViewModel: ObservableObject {
    @Published var isLoading = false
    @Published private(set) var hasLoadedGeneralSettings = false
    @Published private(set) var hasLoadedUserInfo = false
    @Published var initializeFailed = false

    @Published var timeZones: [TimeZoneInfo] = []

    private let appInfoBL = AppInfoBL()

    func loadAppInfo(force: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
         BDSupportSDK.initialize(
            appId: AppConstant.appId,
            brandURl: AppConstant.brandURl,
            { _ in
                Task {
                    await self.loadGeneralSettings(force: force)
                    if !AppConstant.authToken.isEmpty {
                        await self.loadUserInfoAndTimeZonesConcurrently(force: force)
                    }
                }
            },
            { error in
                DispatchQueue.main.async {
                    self.initializeFailed = true
                }
            }
        )
    }

    internal func loadGeneralSettings(force: Bool = false) async {
        guard force || !hasLoadedGeneralSettings else { return }

        do {
            let response = try await appInfoBL.getGeneralSetting(
                sdkId: AppConstant.mobileSDKId
            )
            if response.isSuccess,
                let rawData = response.data as? [String: Any],
                let result = rawData["result"] as? [String: Any]
            {

                let jsonData = try JSONSerialization.data(
                    withJSONObject: result
                )
                let decoded = try JSONDecoder().decode(
                    GeneralSettingResult.self,
                    from: jsonData
                )

                AppSettingsManager.shared.updateSettings(
                    general: decoded.generalSettings,
                    knowledgeBase: decoded.knowledgeBase,
                    contactUs: decoded.contactUs
                )
                AppConstant.maxFileSizeInMB = Int(bytesToMegabytes(
                    Int64(GeneralSettings.uploadFileSize)
                ))

                hasLoadedGeneralSettings = true
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "Get General Settings in AppInfoViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }

    private func loadUserInfoAndTimeZonesConcurrently(force: Bool) async {
        async let userInfoResult = loadUserInfo(force: force)
        async let timeZoneResult = getTimeZones()

        let (userInfoLoaded, timeZonesLoaded) = await (
            userInfoResult, timeZoneResult
        )

        if userInfoLoaded && timeZonesLoaded {
            hasLoadedUserInfo = true
            setupDateTimeSetting()
        }
    }

    private func loadUserInfo(force: Bool = false) async -> Bool {
        guard force || !hasLoadedUserInfo else { return true }

        do {
            let response = try await appInfoBL.getUserInfo()
            if response.isSuccess,
                let rawData = response.data as? [String: Any],
                let result = rawData["result"] as? [String: Any]
            {

                let jsonData = try JSONSerialization.data(
                    withJSONObject: result
                )
                let decoded = try JSONDecoder().decode(
                    UserInfo.self,
                    from: jsonData
                )

                UserInfoManager.shared.updateUserInfo(decoded)
                return true
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
                return false
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "Get User Info in AppInfoViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
            return false
        }
    }

    private func getTimeZones() async -> Bool {
        do {
            let response = try await appInfoBL.getTimeZones()

            if response.isSuccess,
                let rawData = response.data as? [String: Any],
                let jsonData = try? JSONSerialization.data(
                    withJSONObject: rawData
                )
            {

                let decoded = try JSONDecoder().decode(
                    TimeZoneResponse.self,
                    from: jsonData
                )
                self.timeZones = decoded.result.sorted(by: { $0.name < $1.name }
                )
                return true
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
                return false
            }
        } catch {
            ToastManager.shared.show(error.localizedDescription, type: .error)
            return false
        }
    }

    private func setupDateTimeSetting() {
        let userTimeZoneId = UserInfo.current?.timeZoneId
        let selectedTimeZoneId =
            (userTimeZoneId ?? 0) > 0
            ? userTimeZoneId! : GeneralSettings.timeZoneId

        let selectedTimeZone = timeZones.first { $0.id == selectedTimeZoneId }

        let fallbackTimeZone = TimeZoneInfo(
            id: GeneralSettings.timeZoneId,
            standardName: GeneralSettings.timeZoneName,
            dayLightName: "",
            shortCode: GeneralSettings.ianaTimeZoneName,
            offset: "",
            name: GeneralSettings.timeZoneName,
            timeZoneId: "",
            ianaTimeZoneName: GeneralSettings.ianaTimeZoneName
        )

        let timeZoneToUse = selectedTimeZone ?? fallbackTimeZone

        let dateFormatId = GeneralSettings.dateFormatId
        let dateFormat =
            DateFormats.all.first(where: { $0.value == dateFormatId })?.text
            ?? "dd/MM/yyyy"

        let timeFormatId = GeneralSettings.timeFormatId
        let timeFormat =
            GeneralSettings.current?.timeFormat ?? TimeFormats.all.first(
                where: { $0.value == timeFormatId })?.text ?? "24HRCLOCK"

        let dateTimeSetting = DateTimeSetting(
            dateFormatId: dateFormatId,
            dateFormat: dateFormat,
            ianaTimeZoneName: timeZoneToUse.ianaTimeZoneName,
            timeFormatId: timeFormatId,
            timeFormat: timeFormat,
            timeZoneId: timeZoneToUse.id,
            timeZoneName: extractUTCOffset(from: timeZoneToUse.name),
        )

        DateTimeSettingManager.shared.updateSetting(dateTimeSetting)
    }

    func extractUTCOffset(from text: String) -> String {
        let parts = text.split(separator: ")", maxSplits: 1)

        guard let firstPart = parts.first else { return "(UTC-11:00" }

        return "\(firstPart))"
    }
}
