import SwiftUI

struct GlobalTooltipState {
    private(set) static var tooltipStates: [Binding<Bool>] = []

    static func register(_ binding: Binding<Bool>) {
        tooltipStates.append(binding)
    }

    static func resetAll() {
        for tooltip in tooltipStates {
            tooltip.wrappedValue = false
        }
    }

    static func clearAll() {
        tooltipStates.removeAll()
    }
}
