import Foundation

// MARK: - TicketDetailModel
struct TicketDetailModel: Decodable {
    let ticketId: Int?
    let requester: Requester?
    let categoryId: Category?
    let typeId: TicketType?
    let cc: String?
    let status: String?
    let statusTextColor: String?
    let statusBackgroundColor: String?
    let createdOn: String?
    let lastActivity: String?
    let closedOn: String?
    let customFieldObject: String?
    let customFields: [CustomFormFieldsModel]?
    let agent: String?
    let group: String?
    let priorityId: Category?
    let labelForAgent: String?
    let labelForGroup: String?
    let brandOptionId: Int?
    let contactGroup: Category?
    let ticketStatusId: Int?
    let resolutionDue: String?
    let ticketFormDetails: TicketFormDetails?
    let statusOptionId: Int?

    enum CodingKeys: String, CodingKey {
        case ticketId, requester, categoryId, typeId, cc, status, statusTextColor, statusBackgroundColor, createdOn, lastActivity, closedOn, customFieldObject, customFields, agent, group, priorityId, labelForAgent, labelForGroup, brandOptionId, contactGroup, ticketStatusId, resolutionDue, ticketFormDetails, statusOptionId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        ticketId = try container.decodeIfPresent(Int.self, forKey: .ticketId)
        requester = try container.decodeIfPresent(Requester.self, forKey: .requester)
        categoryId = try container.decodeIfPresent(Category.self, forKey: .categoryId)
        typeId = try container.decodeIfPresent(TicketType.self, forKey: .typeId)
        cc = try container.decodeIfPresent(String.self, forKey: .cc)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        statusTextColor = try container.decodeIfPresent(String.self, forKey: .statusTextColor)
        statusBackgroundColor = try container.decodeIfPresent(String.self, forKey: .statusBackgroundColor)
        createdOn = try container.decodeIfPresent(String.self, forKey: .createdOn)
        lastActivity = try container.decodeIfPresent(String.self, forKey: .lastActivity)
        closedOn = try container.decodeIfPresent(String.self, forKey: .closedOn)
        customFieldObject = try container.decodeIfPresent(String.self, forKey: .customFieldObject)
        agent = try container.decodeIfPresent(String.self, forKey: .agent)
        group = try? container.decodeIfPresent(String.self, forKey: .group)
        priorityId = try container.decodeIfPresent(Category.self, forKey: .priorityId)
        labelForAgent = try container.decodeIfPresent(String.self, forKey: .labelForAgent)
        labelForGroup = try container.decodeIfPresent(String.self, forKey: .labelForGroup)
        brandOptionId = try container.decodeIfPresent(Int.self, forKey: .brandOptionId)
        contactGroup = try container.decodeIfPresent(Category.self, forKey: .contactGroup)
        ticketStatusId = try container.decodeIfPresent(Int.self, forKey: .ticketStatusId)
        resolutionDue = try container.decodeIfPresent(String.self, forKey: .resolutionDue)
        ticketFormDetails = try container.decodeIfPresent(TicketFormDetails.self, forKey: .ticketFormDetails)
        statusOptionId = try container.decodeIfPresent(Int.self, forKey: .statusOptionId)

        // Custom decoding of dynamic key-value map
        if let fieldMap = try? container.decode([String: AnyCodable].self, forKey: .customFields) {
            customFields = fieldMap.map { CustomFormFieldsModel(apiName: $0.key, formFieldsContents: $0.value) }
        } else {
            customFields = nil
        }
    }
}

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { return nil }

    init?(intValue: Int) {
        return nil
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }
}


// MARK: - CustomFormFieldsModel
struct CustomFormFieldsModel {
    var apiName: String = ""
    var formFieldsContents: AnyCodable

    init(apiName: String, formFieldsContents: AnyCodable) {
        self.apiName = apiName
        self.formFieldsContents = formFieldsContents
    }
}

// MARK: - Requester
struct Requester: Decodable {
    let shortCode: String?
    let colorCode: String?
    let displayName: String?
    let userId: Int?
    let isAgent: Bool?
    let email: String?
    let profileImageUrl: String?
}

// MARK: - Ticket Type Model
struct TicketType: Codable {
    let id: Int
    let name: String
}

// MARK: - Category
struct Category: Decodable {
    let id: Int?
    let name: String?
}

struct TicketFormDetails: Decodable {
    let id: Int?
    let name: String?
}

// MARK: - AnyCodable
struct AnyCodable: Codable {
    let value: Any?

    init(_ value: Any?) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
        } else if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let strVal = try? container.decode(String.self) {
            value = strVal
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case nil:
            try container.encodeNil()
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let strVal as String:
            try container.encode(strVal)
        case let dictVal as [String: AnyCodable]:
            try container.encode(dictVal)
        case let arrayVal as [AnyCodable]:
            try container.encode(arrayVal)
        default:
            throw EncodingError.invalidValue(value as Any, .init(codingPath: encoder.codingPath, debugDescription: "Unsupported value"))
        }
    }
}
