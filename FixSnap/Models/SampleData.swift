import Foundation
import CoreLocation

struct FaultReport: Codable, Equatable, Identifiable {
    let id: String?
    let faultType: String
    let category: String
    let severity: String
    let summary: String
    let suggestion: FaultSuggestion
    let detectedParts: [DetectedPart]
    let routedTechnicians: [Technician]
    let telegramSent: Bool
    let telegramMessageID: Int?
    let routedGroup: String?
    let countryName: String?
    let countryCode: String?
    let city: String?
    let imageURL: String?
    let telegramDebug: String?

    enum CodingKeys: String, CodingKey {
        case id
        case faultType
        case category
        case severity
        case summary
        case suggestion
        case detectedParts
        case routedTechnicians
        case telegramSent
        case telegramMessageID = "telegramMessageId"
        case routedGroup
        case countryName
        case countryCode
        case city
        case imageURL = "imageUrl"
        case telegramDebug
    }

    var steps: [String] { suggestion.steps }
    var tools: [String] { suggestion.tools }
    var estimatedCost: String { suggestion.estimatedCostRange }
    var estimatedTime: String { suggestion.estimatedTime }
    var safetyWarning: String { suggestion.safetyWarning }
    var parts: [DetectedPart] { detectedParts }
    var technicians: [Technician] { routedTechnicians }

    init(
        id: String? = nil,
        faultType: String,
        category: String,
        severity: String,
        summary: String,
        suggestion: FaultSuggestion,
        detectedParts: [DetectedPart] = [],
        routedTechnicians: [Technician] = [],
        telegramSent: Bool = false,
        telegramMessageID: Int? = nil,
        routedGroup: String? = nil,
        countryName: String? = nil,
        countryCode: String? = nil,
        city: String? = nil,
        imageURL: String? = nil,
        telegramDebug: String? = nil
    ) {
        self.id = id
        self.faultType = faultType
        self.category = category
        self.severity = severity
        self.summary = summary
        self.suggestion = suggestion
        self.detectedParts = detectedParts
        self.routedTechnicians = routedTechnicians
        self.telegramSent = telegramSent
        self.telegramMessageID = telegramMessageID
        self.routedGroup = routedGroup
        self.countryName = countryName
        self.countryCode = countryCode
        self.city = city
        self.imageURL = imageURL
        self.telegramDebug = telegramDebug
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        faultType = try container.decode(String.self, forKey: .faultType)
        category = try container.decode(String.self, forKey: .category)
        severity = try container.decode(String.self, forKey: .severity)
        summary = try container.decode(String.self, forKey: .summary)
        suggestion = try container.decodeIfPresent(FaultSuggestion.self, forKey: .suggestion) ?? .empty
        detectedParts = try container.decodeIfPresent([DetectedPart].self, forKey: .detectedParts) ?? []
        routedTechnicians = try container.decodeIfPresent([Technician].self, forKey: .routedTechnicians) ?? []
        telegramSent = try container.decodeIfPresent(Bool.self, forKey: .telegramSent) ?? false
        telegramMessageID = try container.decodeIfPresent(Int.self, forKey: .telegramMessageID)
        routedGroup = try container.decodeIfPresent(String.self, forKey: .routedGroup)
        countryName = try container.decodeIfPresent(String.self, forKey: .countryName)
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        telegramDebug = try container.decodeIfPresent(String.self, forKey: .telegramDebug)
    }

    static let sample = FaultReport(
        id: "sample-report",
        faultType: "Leaking Pipe Joint",
        category: "Plumbing",
        severity: "Medium",
        summary: "Corroded compression fitting under the kitchen sink is causing a slow, steady drip.",
        suggestion: FaultSuggestion(
            steps: [
                "Shut off the water supply valve",
                "Loosen the compression nut with a wrench",
                "Replace the worn rubber washer",
                "Re-tighten and check for leaks"
            ],
            tools: ["Adjustable wrench", "PTFE tape", "Replacement washer"],
            estimatedCostRange: "$18 - $45",
            estimatedTime: "30-45 min",
            safetyWarning: "Turn off the main water valve before attempting any repair.",
            recommendProfessional: true
        ),
        detectedParts: [
            DetectedPart(name: "Compression Fitting", displayName: "Compression Fitting", confidence: 92, basePriceUSD: 6, priceLocal: "S$8", boundingBox: PartBoundingBox(x: 0.24, y: 0.35, width: 0.34, height: 0.22)),
            DetectedPart(name: "Rubber Washer", displayName: "Rubber Washer", confidence: 87, basePriceUSD: 1.5, priceLocal: "S$2", boundingBox: PartBoundingBox(x: 0.52, y: 0.42, width: 0.16, height: 0.12)),
            DetectedPart(name: "Copper Pipe Section", displayName: "Copper Pipe Section", confidence: 74, basePriceUSD: 10, priceLocal: "S$14", boundingBox: nil)
        ],
        routedTechnicians: [
            Technician(name: "Tan Plumbing Services", trade: "Plumbing", location: "Toa Payoh, Singapore", phone: "+6591234567", city: "Singapore", district: "Toa Payoh"),
            Technician(name: "Rapid Fix Co.", trade: "Plumbing", location: "Bedok, Singapore", phone: "+6598765432", city: "Singapore", district: "Bedok"),
            Technician(name: "Island Wide Repairs", trade: "Plumbing", location: "Jurong, Singapore", phone: "+6590011223", city: "Singapore", district: "Jurong")
        ],
        telegramSent: true,
        telegramMessageID: 42,
        routedGroup: "Singapore Plumbing",
        countryName: "Singapore",
        countryCode: "SG",
        city: "Singapore",
        imageURL: nil,
        telegramDebug: nil
    )
}

struct FaultSuggestion: Codable, Equatable {
    let steps: [String]
    let tools: [String]
    let estimatedCostRange: String
    let estimatedTime: String
    let safetyWarning: String
    let recommendProfessional: Bool?

    static let empty = FaultSuggestion(
        steps: [],
        tools: [],
        estimatedCostRange: "Price varies",
        estimatedTime: "Time varies",
        safetyWarning: "Follow standard safety precautions before attempting any repair.",
        recommendProfessional: nil
    )

    init(
        steps: [String] = [],
        tools: [String] = [],
        estimatedCostRange: String = "Price varies",
        estimatedTime: String = "Time varies",
        safetyWarning: String = "Follow standard safety precautions before attempting any repair.",
        recommendProfessional: Bool? = nil
    ) {
        self.steps = steps
        self.tools = tools
        self.estimatedCostRange = estimatedCostRange
        self.estimatedTime = estimatedTime
        self.safetyWarning = safetyWarning
        self.recommendProfessional = recommendProfessional
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        steps = try container.decodeIfPresent([String].self, forKey: .steps) ?? []
        tools = try container.decodeIfPresent([String].self, forKey: .tools) ?? []
        estimatedCostRange = try container.decodeIfPresent(String.self, forKey: .estimatedCostRange) ?? "Price varies"
        estimatedTime = try container.decodeIfPresent(String.self, forKey: .estimatedTime) ?? "Time varies"
        safetyWarning = try container.decodeIfPresent(String.self, forKey: .safetyWarning) ?? "Follow standard safety precautions before attempting any repair."
        recommendProfessional = try container.decodeIfPresent(Bool.self, forKey: .recommendProfessional)
    }
}

struct DetectedPart: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let displayName: String
    let confidence: Int
    let basePriceUSD: Double?
    let priceLocal: String?
    let boundingBox: PartBoundingBox?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case displayName
        case confidence
        case basePriceUSD = "basePriceUsd"
        case priceLocal
        case boundingBox
    }

    init(
        id: UUID = UUID(),
        name: String,
        displayName: String? = nil,
        confidence: Int,
        basePriceUSD: Double? = nil,
        priceLocal: String? = nil,
        boundingBox: PartBoundingBox? = nil
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName ?? name
        self.confidence = confidence
        self.basePriceUSD = basePriceUSD
        self.priceLocal = priceLocal
        self.boundingBox = boundingBox
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? container.decode(String.self, forKey: .displayName)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? name
        confidence = try container.decodeIfPresent(Int.self, forKey: .confidence) ?? 0
        basePriceUSD = try container.decodeIfPresent(Double.self, forKey: .basePriceUSD)
        priceLocal = try container.decodeIfPresent(String.self, forKey: .priceLocal)
        boundingBox = try container.decodeIfPresent(PartBoundingBox.self, forKey: .boundingBox)
    }
}

struct PartBoundingBox: Codable, Equatable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct Technician: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let trade: String
    let location: String
    let phone: String
    let phoneSecondary: String?
    let city: String?
    let district: String?
    let sourceURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case trade
        case category
        case location
        case locationText
        case phone
        case phonePrimary
        case phoneSecondary
        case city
        case district
        case sourceURL = "sourceUrl"
    }

    init(
        id: UUID = UUID(),
        name: String,
        trade: String,
        location: String,
        phone: String,
        phoneSecondary: String? = nil,
        city: String? = nil,
        district: String? = nil,
        sourceURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.trade = trade
        self.location = location
        self.phone = phone
        self.phoneSecondary = phoneSecondary
        self.city = city
        self.district = district
        self.sourceURL = sourceURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        trade = try container.decodeIfPresent(String.self, forKey: .trade) ?? container.decodeIfPresent(String.self, forKey: .category) ?? "Technician"
        let locationText = try container.decodeIfPresent(String.self, forKey: .locationText)
        let city = try container.decodeIfPresent(String.self, forKey: .city)
        let district = try container.decodeIfPresent(String.self, forKey: .district)
        self.city = city
        self.district = district
        location = try container.decodeIfPresent(String.self, forKey: .location) ?? locationText ?? [city, district].compactMap { $0 }.joined(separator: ", ")
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? container.decodeIfPresent(String.self, forKey: .phonePrimary) ?? ""
        phoneSecondary = try container.decodeIfPresent(String.self, forKey: .phoneSecondary)
        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(trade, forKey: .trade)
        try container.encode(location, forKey: .location)
        try container.encode(phone, forKey: .phone)
        try container.encodeIfPresent(phoneSecondary, forKey: .phoneSecondary)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(district, forKey: .district)
        try container.encodeIfPresent(sourceURL, forKey: .sourceURL)
    }
}

struct LocationContext: Codable, Equatable {
    let latitude: Double?
    let longitude: Double?
    let countryCode: String?
    let countryName: String?
    let city: String?
    let address: String?
    let authorizationDenied: Bool

    var isSupportedRegion: Bool {
        guard let countryCode else { return true }
        return SupportedRegion.countryCodes.contains(countryCode.uppercased())
    }

    static let unavailable = LocationContext(
        latitude: nil,
        longitude: nil,
        countryCode: nil,
        countryName: nil,
        city: nil,
        address: nil,
        authorizationDenied: true
    )
}

enum SupportedRegion {
    static let countryCodes: Set<String> = ["SG", "LK", "US", "UK", "DE"]
}

enum CurrencyConverter {
    static func localPrice(from usd: Double?, countryCode: String?) -> String {
        guard let usd else { return "Price varies" }

        switch countryCode?.uppercased() {
        case "LK":
            return "Rs\(Int((usd * 298).rounded()))"
        case "SG":
            return "S$\(Int((usd * 1.35).rounded()))"
        default:
            return "$\(Int(usd.rounded()))"
        }
    }
}

enum PhoneValidator {
    static func countryCallingCode(for countryCode: String?) -> String? {
        switch countryCode?.uppercased() {
        case "SG": return "+65"
        case "LK": return "+94"
        case "US": return "+1"
        case "UK", "GB": return "+44"
        case "DE": return "+49"
        default: return nil
        }
    }

    static func normalized(_ phone: String, countryCode: String?) -> String {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.hasPrefix("+"), let callingCode = countryCallingCode(for: countryCode) else {
            return trimmed
        }

        let digits = trimmed.filter(\.isNumber)
        let prefixDigits = callingCode.filter(\.isNumber)
        if digits.hasPrefix(prefixDigits) {
            return "+\(digits)"
        }

        return "\(callingCode)\(digits)"
    }

    static func isValid(_ phone: String, countryCode: String?) -> Bool {
        let digits = normalized(phone, countryCode: countryCode).filter(\.isNumber)
        switch countryCode?.uppercased() {
        case "SG":
            return digits.count == 8 || (digits.hasPrefix("65") && digits.count == 10)
        case "LK":
            return (9...11).contains(digits.count) || (digits.hasPrefix("94") && (11...13).contains(digits.count))
        default:
            return digits.count >= 7
        }
    }
}

enum SampleFaultReport {
    static let report = FaultReport.sample
    static let faultType = report.faultType
    static let category = report.category
    static let severity = report.severity
    static let summary = report.summary
    static let steps = report.steps
    static let tools = report.tools
    static let estimatedCost = report.estimatedCost
    static let estimatedTime = report.estimatedTime
    static let safetyWarning = report.safetyWarning
    static let parts = report.parts
    static let technicians = report.technicians
}
