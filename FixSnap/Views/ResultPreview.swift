import SwiftUI
import MapKit
import UIKit

struct ResultPreview: View {
    let report: FaultReport
    let image: UIImage?
    let location: LocationContext

    @State private var shops: [NearbyShop] = []
    @State private var shopsMessage: String?
    @State private var contactPhone = ""
    @State private var contactAddress = ""
    @State private var contactMessage: String?
    @State private var isSubmittingContact = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 1.3521, longitude: 103.8198),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    private let shopService = NearbyShopService()
    private let analysisService = RepairAnalysisService()

    init(report: FaultReport, image: UIImage? = nil, location: LocationContext = .unavailable) {
        self.report = report
        self.image = image
        self.location = location
        _contactPhone = State(initialValue: Self.defaultPhonePrefix(report: report, location: location))
        _contactAddress = State(initialValue: Self.defaultContactAddress(report: report, location: location))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryCard
                analysisDetailsCard
                photoOverlayCard
                if !report.parts.isEmpty {
                    partsCard
                }
                actionsCard
                if !report.technicians.isEmpty {
                    techniciansCard
                }
                safetyCard
                telegramBadge
                shopsCard
                contactCard
            }
            .padding(20)
        }
        .task {
            await loadShops()
        }
    }

    private var summaryCard: some View {
        FSCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(report.faultType)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    FSBadge(text: report.category, tint: FSColor.teal)
                }
                Spacer()
                FSBadge(text: report.severity, tint: severityColor)
            }

            Text(report.summary)
                .font(.system(size: 13))
                .foregroundStyle(FSColor.textSecondary)

            HStack {
                Label(report.estimatedCost, systemImage: "dollarsign.circle")
                Spacer()
                Label(report.estimatedTime, systemImage: "clock")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(FSColor.teal)
        }
    }

    private var analysisDetailsCard: some View {
        FSCard {
            Text("Analysis details")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            detailRow(title: "Fault type", value: report.faultType)
            detailRow(title: "Category", value: report.category)
            detailRow(title: "Severity", value: report.severity.capitalized)

            if let countryName = report.countryName ?? location.countryName {
                detailRow(title: "Country", value: [countryName, report.countryCode ?? location.countryCode].compactMap { $0 }.joined(separator: " · "))
            } else if let countryCode = report.countryCode ?? location.countryCode {
                detailRow(title: "Country", value: countryCode)
            }

            if let routedGroup = report.routedGroup {
                detailRow(title: "Routed group", value: routedGroup)
            }

            if let messageID = report.telegramMessageID {
                detailRow(title: "Telegram message", value: "#\(messageID)")
            }

            if let telegramDebug = report.telegramDebug, !telegramDebug.isEmpty {
                Divider().background(FSColor.stroke)
                Text(telegramDebug)
                    .font(.system(size: 12))
                    .foregroundStyle(FSColor.textSecondary)
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(FSColor.textSecondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var photoOverlayCard: some View {
        FSCard {
            Text("Photo analysis")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(FSColor.inkElevated)
                        .overlay(Image(systemName: "photo").foregroundStyle(FSColor.textSecondary))
                }

                GeometryReader { proxy in
                    Canvas { context, size in
                        for part in report.parts {
                            guard let box = part.boundingBox else { continue }
                            let rect = CGRect(
                                x: box.x * size.width,
                                y: box.y * size.height,
                                width: box.width * size.width,
                                height: box.height * size.height
                            )
                            context.stroke(Path(rect), with: .color(FSColor.flame), lineWidth: 2)
                        }
                    }

                    ForEach(report.parts.filter { $0.boundingBox != nil }) { part in
                        if let box = part.boundingBox {
                            Text("\(part.displayName) \(part.confidence)%")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(FSColor.flame, in: Capsule())
                                .position(
                                    x: max(42, box.x * proxy.size.width),
                                    y: max(14, box.y * proxy.size.height - 12)
                                )
                        }
                    }
                }
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var partsCard: some View {
        FSCard {
            Text("Detected parts")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            ForEach(report.parts) { part in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(part.displayName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                        Text("\(part.confidence)% confidence")
                            .font(.system(size: 11))
                            .foregroundStyle(FSColor.textSecondary)
                    }
                    Spacer()
                    Text(part.priceLocal ?? CurrencyConverter.localPrice(from: part.basePriceUSD, countryCode: report.countryCode ?? location.countryCode))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(FSColor.flame)
                }
                if part.id != report.parts.last?.id {
                    Divider().background(FSColor.stroke)
                }
            }
        }
    }

    private var actionsCard: some View {
        FSCard {
            Text("Recommended actions")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            ForEach(report.steps, id: \.self) { step in
                Label(step, systemImage: "checkmark.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(FSColor.textSecondary)
            }

            if !report.tools.isEmpty {
                Divider().background(FSColor.stroke)
                Text("Tools: \(report.tools.joined(separator: ", "))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(FSColor.teal)
            }
        }
    }

    private var techniciansCard: some View {
        FSCard {
            Text("Suggested technicians")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            ForEach(report.technicians.prefix(5)) { tech in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tech.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                        Text("\(tech.trade) · \(tech.location)")
                            .font(.system(size: 11))
                            .foregroundStyle(FSColor.textSecondary)
                    }
                    Spacer()
                    Button {
                        if let url = URL(string: "tel://\(tech.phone.filter { $0.isNumber || $0 == "+" })") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(FSColor.teal, in: Circle())
                    }
                }
                if tech.id != report.technicians.prefix(5).last?.id {
                    Divider().background(FSColor.stroke)
                }
            }
        }
    }

    private var safetyCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
            Text(report.safetyWarning)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.red)
        }
        .padding(14)
        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.3), lineWidth: 1))
    }

    private var telegramBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: report.telegramSent ? "paperplane.circle.fill" : "paperplane.circle")
                .foregroundStyle(report.telegramSent ? FSColor.teal : FSColor.flame)
            Text(report.telegramSent ? "Sent to fixer network ✓" : "Telegram routing pending")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            if let routedGroup = report.routedGroup {
                Text(routedGroup)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(FSColor.textSecondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(FSColor.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(FSColor.stroke, lineWidth: 1))
    }

    private var shopsCard: some View {
        FSCard {
            Text("Nearby shops")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            if location.latitude == nil || location.longitude == nil {
                Text("Enable location to see nearby hardware and repair shops.")
                    .font(.system(size: 12))
                    .foregroundStyle(FSColor.textSecondary)
            } else {
                Map(coordinateRegion: $region, annotationItems: shops) { shop in
                    MapMarker(coordinate: CLLocationCoordinate2D(latitude: shop.latitude, longitude: shop.longitude), tint: .orange)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if let shopsMessage {
                    Text(shopsMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(FSColor.textSecondary)
                }

                ForEach(shops.prefix(4)) { shop in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(shop.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                            Text("\(shop.type.capitalized) · \(Int(shop.distanceMeters))m away")
                                .font(.system(size: 11))
                                .foregroundStyle(FSColor.textSecondary)
                        }
                        Spacer()
                        Button("Directions") {
                            openDirections(to: shop)
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FSColor.teal)
                    }
                }
            }
        }
    }

    private var contactCard: some View {
        FSCard {
            Text("Request contact")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            TextField("Phone number", text: $contactPhone)
                .keyboardType(.phonePad)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(12)
                .background(FSColor.inkElevated, in: RoundedRectangle(cornerRadius: 12))

            TextField("Address", text: $contactAddress, axis: .vertical)
                .lineLimit(2...3)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(12)
                .background(FSColor.inkElevated, in: RoundedRectangle(cornerRadius: 12))

            Button {
                Task { await submitContact() }
            } label: {
                Text(isSubmittingContact ? "Sending..." : "Send contact details")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(FSColor.teal, in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isSubmittingContact || !canSubmitContact)
            .opacity((isSubmittingContact || !canSubmitContact) ? 0.55 : 1)

            if let contactMessage {
                Text(contactMessage)
                    .font(.system(size: 12))
                    .foregroundStyle(FSColor.textSecondary)
            }
        }
    }

    private var canSubmitContact: Bool {
        true
    }

    private var effectiveCountryCode: String? {
        report.countryCode ?? location.countryCode
    }

    private var severityColor: Color {
        switch report.severity.lowercased() {
        case "low": return .green
        case "medium": return .yellow
        case "high": return FSColor.flame
        case "critical", "emergency": return .red
        default: return FSColor.teal
        }
    }

    @MainActor
    private func loadShops() async {
        guard let latitude = location.latitude, let longitude = location.longitude else { return }
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )

        do {
            shopsMessage = "Searching nearby repair and hardware shops..."
            shops = try await shopService.fetchNearbyShops(latitude: latitude, longitude: longitude)
            shopsMessage = shops.isEmpty ? "No nearby repair or hardware shops found." : nil
        } catch {
            shops = []
            shopsMessage = "Could not load nearby shops."
        }
    }

    @MainActor
    private func submitContact() async {
        guard canSubmitContact else {
            contactMessage = "This report cannot accept contact details yet."
            return
        }

        let normalizedPhone = PhoneValidator.normalized(contactPhone, countryCode: effectiveCountryCode)
        guard PhoneValidator.isValid(normalizedPhone, countryCode: effectiveCountryCode) else {
            contactMessage = "Enter a valid phone number for your country."
            return
        }

        let trimmedAddress = contactAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAddress.isEmpty else {
            contactMessage = "Enter the address for the fixer contact."
            return
        }

        isSubmittingContact = true
        defer { isSubmittingContact = false }

        do {
            try await analysisService.sendContact(report: report, location: location, phone: normalizedPhone, address: trimmedAddress)
            contactPhone = normalizedPhone
            contactAddress = trimmedAddress
            contactMessage = "Contact details sent to the fixer group."
        } catch {
            contactMessage = error.localizedDescription
        }
    }

    private static func defaultPhonePrefix(report: FaultReport, location: LocationContext) -> String {
        PhoneValidator.countryCallingCode(for: report.countryCode ?? location.countryCode).map { "\($0) " } ?? ""
    }

    private static func defaultContactAddress(report: FaultReport, location: LocationContext) -> String {
        if let address = location.address?.trimmingCharacters(in: .whitespacesAndNewlines), !address.isEmpty {
            return address
        }

        let locationParts = [location.city, report.countryName ?? location.countryName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !locationParts.isEmpty {
            return locationParts.joined(separator: ", ")
        }

        if let latitude = location.latitude, let longitude = location.longitude {
            return String(format: "%.5f, %.5f", latitude, longitude)
        }

        return ""
    }

    private func openDirections(to shop: NearbyShop) {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: shop.latitude, longitude: shop.longitude))
        let item = MKMapItem(placemark: placemark)
        item.name = shop.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

#Preview {
    ResultPreview(report: .sample, image: nil, location: LocationContext(latitude: 1.3521, longitude: 103.8198, countryCode: "SG", countryName: "Singapore", city: "Singapore", address: "Singapore", authorizationDenied: false))
        .background(FSColor.ink)
}
