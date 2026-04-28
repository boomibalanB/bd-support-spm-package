enum DefaultFieldAPIName: String, CaseIterable, Codable, Identifiable {
    case requester = "requesterId"
    case subject = "subject"
    case description = "description"
    case assignee = "assignee"
    case tag = "tag"
    case watchersUserId = "watchersUserId"
    case priority = "priorityId"
    case category = "categoryId"
    case type = "typeId"
    case group = "groupId"
    case agent = "agentId"
    case resolutionDue = "resolutionDue"
    case responseDue = "responseDue"
    case visibility = "visibility"
    case cc = "cc"
    case isVisibleInCustomerPortal = "isVisibleInCustomerPortal"
    case brand = "brandId"
    case activityAgent = "activityAgent"
    case activityCCField = "activityCCField"
    case activityCollaborators = "activityCollaborators"
    case activityDescription = "activityDescription"
    case activityDueDate = "activityDueDate"
    case activityDuration = "activityDuration"
    case activityEndTime = "activityEndTime"
    case activityFileUpload = "activityFileUpload"
    case activityIsAllDay = "activityIsAllDay"
    case activityLinkedTicket = "activityLinkedTicket"
    case activityLinkedUser = "activityLinkedUser"
    case activityPriority = "activityPriority"
    case activityStartTime = "activityStartTime"
    case activityStatus = "activityStatus"
    case activitySubject = "activitySubject"
    case activityTimeZone = "activityTimeZone"
    case activityToAddress = "activityToAddress"
    case activityType = "activityType"
    case activityLinkedTicketUpdate = "activityLinkedTicketUpdate"
    case activityId = "activityId"
    case status = "statusId"
    case activityTag = "activityTag"
    case approval = "approvalRequests"
    case slaOnHold = "SLAOnHold"
    case externalReferenceId = "externalReferenceId"
    case activityIntegrationApp = "activityIntegrationApp"
    case form = "formId"
    case chatStatus = "chatStatusId"
    case chatAgent = "chatAgentId"
    case chatGroup = "chatGroupId"
    case chatTag = "chatTag"
    case chatContactGroupId = "chatContactGroupId"
    case chatCategory = "chatCategoryId"
    case chatBrandId = "chatBrandId"
    case chatPriority = "chatPriorityId"
    case chatConversationParticipantId = "chatConversationParticipantId"

    var value: String {
        rawValue
    }

    // Conform to Identifiable for SwiftUI
    var id: String {
        rawValue
    }
}

enum DefaultFieldName: String, CaseIterable, Codable, Identifiable {
    case requester = "Requester"
    case subject = "Subject"
    case description = "Description"
    case assignee = "Assignee"
    case tag = "Tags"
    case watchers = "Watchers"
    case group = "Group"
    case agent = "Agent"
    case priority = "priorityId"
    case resolutionDue = "resolutionDue"
    case responseDue = "Response Due"
    case visibility = "Visibility"
    case cc = "CCs"
    case status = "Status"
    case approvalRequests = "ApprovalRequests"
    case slaOnHold = "SLA On Hold"
    case form = "Form"

    var value: String {
        rawValue
    }

    // Conform to Identifiable for SwiftUI
    var id: String {
        rawValue
    }
}
