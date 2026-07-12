import SwiftUI

struct ResultPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryCard
                partsCard
                techniciansCard
                safetyCard
                telegramBadge
            }
            .padding(20)
        }
    }

    private var summaryCard: some View {
        FSCard {
            HStack {
                Text(SampleFaultReport.faultType)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                FSBadge(text: SampleFaultReport.severity, tint: .yellow)
            }
            FSBadge(text: SampleFaultReport.category, tint: FSColor.teal)
            Text(SampleFaultReport.summary)
                .font(.system(size: 13))
                .foregroundStyle(FSColor.textSecondary)

            Divider().background(FSColor.stroke)

            Text("Suggested steps")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
            ForEach(SampleFaultReport.steps, id: \.self) { step in
                Label(step, systemImage: "checkmark.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(FSColor.textSecondary)
            }
            HStack {
                Label(SampleFaultReport.estimatedCost, systemImage: "dollarsign.circle")
                Spacer()
                Label(SampleFaultReport.estimatedTime, systemImage: "clock")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(FSColor.teal)
        }
    }

    private var partsCard: some View {
        FSCard {
            Text("Detected parts")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            ForEach(SampleFaultReport.parts) { part in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(part.name).font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
                        Text("\(part.confidence)% confidence").font(.system(size: 11)).foregroundStyle(FSColor.textSecondary)
                    }
                    Spacer()
                    Text(part.priceLocal).font(.system(size: 13, weight: .semibold)).foregroundStyle(FSColor.flame)
                }
                if part.id != SampleFaultReport.parts.last?.id {
                    Divider().background(FSColor.stroke)
                }
            }
        }
    }

    private var techniciansCard: some View {
        FSCard {
            Text("Nearby technicians")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            ForEach(SampleFaultReport.technicians) { tech in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tech.name).font(.system(size: 13, weight: .medium)).foregroundStyle(.white)
                        Text("\(tech.trade) · \(tech.location)").font(.system(size: 11)).foregroundStyle(FSColor.textSecondary)
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
                if tech.id != SampleFaultReport.technicians.last?.id {
                    Divider().background(FSColor.stroke)
                }
            }
        }
    }

    private var safetyCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
            Text(SampleFaultReport.safetyWarning)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.red)
        }
        .padding(14)
        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.3), lineWidth: 1))
    }

    private var telegramBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "paperplane.circle.fill").foregroundStyle(FSColor.teal)
            Text("Sent to fixer network ✓")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(FSColor.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(FSColor.stroke, lineWidth: 1))
    }
}

#Preview {
    ResultPreview().background(FSColor.ink)
}
