import Foundation
import UIKit

enum RepairAnalysisError: LocalizedError {
    case invalidImage
    case missingConfiguration(String)
    case invalidResponse
    case unsupportedRegion
    case backendMessage(String)
    case requestFailed(service: String, statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not prepare the photo for upload."
        case .missingConfiguration(let key):
            return "Missing \(key) in Info.plist."
        case .invalidResponse:
            return "The repair service returned an unreadable response."
        case .unsupportedRegion:
            return "FixSnap is only available in Singapore and Sri Lanka. We detected your location outside our service area."
        case .backendMessage(let message):
            return message
        case .requestFailed(let service, let statusCode):
            return "\(service) request failed with status \(statusCode)."
        }
    }
}

struct RepairAnalysisService {
    private let session: URLSession
    private let configuration: APIConfiguration

    init(session: URLSession = .shared, configuration: APIConfiguration = .current) {
        self.session = session
        self.configuration = configuration
    }

    func analyze(image: UIImage, location: LocationContext, description: String?) async throws -> FaultReport {
//        if !location.isSupportedRegion {
//            throw RepairAnalysisError.unsupportedRegion
//        }

        let imageUrl = try await uploadPhoto(image)
        

        let requestBody = AnalyzeFaultRequest(
            imageUrl: "https://rbkcojkwecbvwczhuimk.supabase.co/storage/v1/object/public/fault-images/\(imageUrl)",
            countryCode: location.countryCode?.lowercased(),
            countryName: location.countryName,
            city: location.city,
            latitude: location.latitude,
            longitude: location.longitude,
            description: description?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )

        var request = URLRequest(
            url: try configuration.edgeFunctionURL(named: "analyze-fault")
        )
        request.httpMethod = "POST"
        request.timeoutInterval = 100
        applyBoltHeaders(to: &request)

        let bodyData = try JSONEncoder.fixSnap.encode(requestBody)
        request.httpBody = bodyData

        print("[DEBUG] Request JSON: \(String(data: bodyData, encoding: .utf8) ?? "")")

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("[DEBUG] HTTP Status: \(httpResponse.statusCode)")
        }

        print("[DEBUG] Response Body: \(String(data: data, encoding: .utf8) ?? "")")

        try validate(response: response, data: data, service: "analyze-fault")

        return try JSONDecoder.fixSnap.decode(FaultReport.self, from: data)    }

    func sendContact(report: FaultReport, location: LocationContext, phone: String, address: String) async throws {
        let requestBody = SendContactRequest(
            reportID: report.id,
            faultType: report.faultType,
            countryCode: report.countryCode ?? location.countryCode,
            countryName: report.countryName ?? location.countryName,
            city: report.city ?? location.city,
            phoneNumber: phone,
            addressText: address
        )
        var request = URLRequest(url: try configuration.edgeFunctionURL(named: "send-contact"))
        request.httpMethod = "POST"
        applyBoltHeaders(to: &request)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data, service: "send-contact")
    }

    /// Uploads the photo to the private storage bucket and returns its object path.
    private func uploadPhoto(_ image: UIImage) async throws -> String {
        guard let imageData = Self.compressedJPEG(from: image) else {
            throw RepairAnalysisError.invalidImage
        }
        let bucket = configuration.value(for: .boltStorageBucket) ?? "fault-images"
        let objectName = "\(UUID().uuidString.lowercased()).jpg"
        let url = try configuration.requiredURL(for: .boltDatabaseURL)
            .appending(path: "storage/v1/object")
            .appending(path: bucket)
            .appending(path: objectName)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        applyBoltHeaders(to: &request, includeContentType: false)
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("false", forHTTPHeaderField: "x-upsert")

        let (data, response) = try await session.upload(for: request, from: imageData)
        try validate(response: response, data: data, service: "photo upload")
        return objectName
    }

    /// Downscales large camera photos and keeps the JPEG well under the 6 MB upload limit.
    private static func compressedJPEG(from image: UIImage) -> Data? {
        let maxSide: CGFloat = 1600
        let longest = max(image.size.width, image.size.height)
        var working = image
        if longest > maxSide {
            let scale = maxSide / longest
            let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1
            working = UIGraphicsImageRenderer(size: target, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: target))
            }
        }
        return working.jpegData(compressionQuality: 0.8)
    }

    private func applyBoltHeaders(to request: inout URLRequest, includeContentType: Bool = true) {
        if includeContentType {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let anonKey = configuration.value(for: .boltAnonKey) {
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }
    }

    private func validate(response: URLResponse, data: Data, service: String) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepairAnalysisError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let serviceError = try? JSONDecoder.fixSnap.decode(ServiceError.self, from: data),
               let message = serviceError.message ?? serviceError.errorDescription ?? serviceError.description ?? serviceError.error {
                throw RepairAnalysisError.backendMessage("\(service): \(message)")
            }
            if let responseText = String(data: data, encoding: .utf8), !responseText.isEmpty {
                throw RepairAnalysisError.backendMessage("\(service) failed with status \(httpResponse.statusCode): \(responseText)")
            }
            throw RepairAnalysisError.requestFailed(service: service, statusCode: httpResponse.statusCode)
        }
    }
}

struct LocationLookupService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> LocationContext {
        var components = URLComponents(string: "https://nominatim.openstreetmap.org/reverse")!
        components.queryItems = [
            URLQueryItem(name: "format", value: "jsonv2"),
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "addressdetails", value: "1")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("FixSnap/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        try validateHTTP(response: response, data: data, service: "Nominatim")

        let payload = try JSONDecoder.fixSnap.decode(NominatimReverseResponse.self, from: data)
        let countryCode = payload.address.countryCode?.uppercased()
        return LocationContext(
            latitude: latitude,
            longitude: longitude,
            countryCode: countryCode,
            countryName: payload.address.country,
            city: payload.address.city ?? payload.address.town ?? payload.address.village ?? payload.address.suburb,
            address: payload.displayName,
            authorizationDenied: false
        )
    }

    private func validateHTTP(response: URLResponse, data: Data, service: String) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepairAnalysisError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw RepairAnalysisError.requestFailed(service: service, statusCode: httpResponse.statusCode)
        }
    }
}

struct NearbyShopService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchNearbyShops(latitude: Double, longitude: Double) async throws -> [NearbyShop] {
        let query = """
        [out:json][timeout:20];
        (
          node["shop"~"hardware|doityourself|car_repair|electronics|computer|mobile_phone|appliance|electrical"](around:8000,\(latitude),\(longitude));
          way["shop"~"hardware|doityourself|car_repair|electronics|computer|mobile_phone|appliance|electrical"](around:8000,\(latitude),\(longitude));
          node["craft"~"electrician|plumber|handyman"](around:8000,\(latitude),\(longitude));
          way["craft"~"electrician|plumber|handyman"](around:8000,\(latitude),\(longitude));
        );
        out center 20;
        """

        var components = URLComponents(string: "https://overpass-api.de/api/interpreter")!
        components.queryItems = [URLQueryItem(name: "data", value: query)]

        var request = URLRequest(url: components.url!)
        request.setValue("FixSnap/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            return []
        }

        let payload = try JSONDecoder.fixSnap.decode(OverpassResponse.self, from: data)
        return payload.elements.compactMap { element in
            let shopLatitude = element.lat ?? element.center?.lat
            let shopLongitude = element.lon ?? element.center?.lon
            guard let shopLatitude, let shopLongitude else { return nil }

            let distance = haversineDistance(
                fromLatitude: latitude,
                fromLongitude: longitude,
                toLatitude: shopLatitude,
                toLongitude: shopLongitude
            )

            return NearbyShop(
                name: element.tags?.name ?? "Nearby repair shop",
                type: element.tags?.shop ?? element.tags?.craft ?? "repair",
                latitude: shopLatitude,
                longitude: shopLongitude,
                distanceMeters: distance
            )
        }
        .sorted { $0.distanceMeters < $1.distanceMeters }
    }

    private func haversineDistance(fromLatitude: Double, fromLongitude: Double, toLatitude: Double, toLongitude: Double) -> Double {
        let earthRadius = 6_371_000.0
        let dLat = (toLatitude - fromLatitude) * .pi / 180
        let dLon = (toLongitude - fromLongitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(fromLatitude * .pi / 180) * cos(toLatitude * .pi / 180)
            * sin(dLon / 2) * sin(dLon / 2)
        return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

struct NearbyShop: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let type: String
    let latitude: Double
    let longitude: Double
    let distanceMeters: Double
}

struct APIConfiguration {
    enum Key: String {
        case boltDatabaseURL = "BOLT_DATABASE_URL"
        case boltAnonKey = "BOLT_DATABASE_ANON_KEY"
        case boltStorageBucket = "BOLT_STORAGE_BUCKET"
    }

    static let current = APIConfiguration()

    func value(for key: Key) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func requiredURL(for key: Key) throws -> URL {
        guard let value = value(for: key), let url = URL(string: value) else {
            throw RepairAnalysisError.missingConfiguration(key.rawValue)
        }
        return url
    }

    func edgeFunctionURL(named functionName: String) throws -> URL {
        try requiredURL(for: .boltDatabaseURL)
            .appending(path: "functions/v1")
            .appending(path: functionName)
    }
}

private struct AnalyzeFaultRequest: Encodable {
    let imageUrl: String
    let countryCode: String?
    let countryName: String?
    let city: String?
    let latitude: Double?
    let longitude: Double?
    let description: String?
}

private struct SendContactRequest: Encodable {
    let reportID: String?
    let faultType: String
    let countryCode: String?
    let countryName: String?
    let city: String?
    let phoneNumber: String
    let addressText: String

    enum CodingKeys: String, CodingKey {
        case reportID = "report_id"
        case faultType = "fault_type"
        case countryCode = "country_code"
        case countryName = "country_name"
        case city
        case phoneNumber = "phone_number"
        case addressText = "address_text"
    }
}

private struct NominatimReverseResponse: Decodable {
    let displayName: String?
    let address: Address

    enum CodingKeys: String, CodingKey {
        case displayName = "displayName"
        case address
    }

    struct Address: Decodable {
        let country: String?
        let countryCode: String?
        let city: String?
        let town: String?
        let village: String?
        let suburb: String?
    }
}

private struct OverpassResponse: Decodable {
    let elements: [Element]

    struct Element: Decodable {
        let lat: Double?
        let lon: Double?
        let center: Center?
        let tags: Tags?
    }

    struct Center: Decodable {
        let lat: Double
        let lon: Double
    }

    struct Tags: Decodable {
        let name: String?
        let shop: String?
        let craft: String?
    }
}

private struct ServiceError: Decodable {
    let message: String?
    let error: String?
    let description: String?
    let errorDescription: String?
}

private extension JSONEncoder {
    static var fixSnap: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

private extension JSONDecoder {
    static var fixSnap: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
