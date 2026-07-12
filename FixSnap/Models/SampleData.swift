import Foundation

struct DetectedPart: Identifiable {
    let id = UUID()
    let name: String
    let confidence: Int
    let priceLocal: String
}

struct Technician: Identifiable {
    let id = UUID()
    let name: String
    let trade: String
    let location: String
    let phone: String
}

struct SampleFaultReport {
    static let faultType = "Leaking Pipe Joint"
    static let category = "Plumbing"
    static let severity = "Medium"
    static let summary = "Corroded compression fitting under the kitchen sink is causing a slow, steady drip."
    static let steps = [
        "Shut off the water supply valve",
        "Loosen the compression nut with a wrench",
        "Replace the worn rubber washer",
        "Re-tighten and check for leaks"
    ]
    static let tools = ["Adjustable wrench", "PTFE tape", "Replacement washer"]
    static let estimatedCost = "S$25 – S$60"
    static let estimatedTime = "30–45 min"
    static let safetyWarning = "Turn off the main water valve before attempting any repair."

    static let parts = [
        DetectedPart(name: "Compression Fitting", confidence: 92, priceLocal: "S$8"),
        DetectedPart(name: "Rubber Washer", confidence: 87, priceLocal: "S$2"),
        DetectedPart(name: "Copper Pipe Section", confidence: 74, priceLocal: "S$14")
    ]

    static let technicians = [
        Technician(name: "Tan Plumbing Services", trade: "Plumber", location: "Toa Payoh, Singapore", phone: "+6591234567"),
        Technician(name: "Rapid Fix Co.", trade: "Plumber", location: "Bedok, Singapore", phone: "+6598765432"),
        Technician(name: "Island Wide Repairs", trade: "Plumber", location: "Jurong, Singapore", phone: "+6590011223")
    ]
}
