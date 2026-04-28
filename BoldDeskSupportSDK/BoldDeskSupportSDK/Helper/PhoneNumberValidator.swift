import Foundation
internal import PhoneNumberKit

internal struct PhoneNumberValidator {

    static let shared = PhoneNumberValidator()

    private let phoneNumberKit: PhoneNumberUtility

    private init() {
        self.phoneNumberKit = PhoneNumberUtility()
    }

    /// Returns E.164 formatted phone number (e.g. +61412345678)
    /// Returns nil if the number is invalid
    func e164(_ number: String, region: String? = nil) -> String? {
        do {
            let phoneNumber: PhoneNumber

            if let region = region, !region.isEmpty {
                // Use provided region
                phoneNumber = try phoneNumberKit.parse(number, withRegion: region)
            } else {
                // Auto-detect region (works when number starts with +)
                phoneNumber = try phoneNumberKit.parse(number)
            }

            return phoneNumberKit.format(phoneNumber, toType: .e164)
        } catch {
            return nil
        }
    }

    /// Validate phone number
    func isValid(_ number: String, region: String? = nil) -> Bool {
        let trimmed = number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let candidate = trimmed.starts(with: "+") ? trimmed : "+" + trimmed
        return e164(candidate, region: region) != nil
    }
}
