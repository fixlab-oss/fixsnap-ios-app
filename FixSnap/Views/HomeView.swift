import SwiftUI

struct HomeView: View {
    @State private var showCapture = false

    var body: some View {
        ZStack {
            FSColor.ink.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 28) {
                    HeroSection(showCapture: $showCapture)
                    HowItWorksSection()
                    FeaturesGridSection()
                    TelegramNetworkSection()
                    FooterSection()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showCapture) {
            CaptureFlowView()
        }
    }
}

private struct HeroSection: View {
    @Binding var showCapture: Bool
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [FSColor.teal.opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: 140))
                    .frame(width: 220, height: 220)
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 54, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(colors: [FSColor.teal, FSColor.flame], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .padding(.top, 8)

            Text("FixSnap")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("AI-assisted repairs · live fixer network")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(FSColor.textSecondary)

            Button {
                showCapture = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                    Text("Capture a fault")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [FSColor.teal, FSColor.flame], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .shadow(color: FSColor.teal.opacity(0.35), radius: 16, y: 8)
            }
            .padding(.top, 6)
        }
    }
}

private struct HowItWorksSection: View {
    let steps: [(String, String, String)] = [
        ("camera.fill", "Snap a photo", "Capture the broken pipe, socket, or vehicle part."),
        ("sparkles", "AI diagnoses it", "GPT-4o Vision identifies the fault, parts and severity."),
        ("bubble.left.and.bubble.right.fill", "Get routed to fixers", "Nearby verified technicians receive it on Telegram instantly.")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "How it works")
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                FSCard {
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            Circle().fill(FSColor.teal.opacity(0.16)).frame(width: 40, height: 40)
                            Image(systemName: step.0).foregroundStyle(FSColor.teal)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(index + 1). \(step.1)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(step.2)
                                .font(.system(size: 13))
                                .foregroundStyle(FSColor.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

private struct FeaturesGridSection: View {
    let features: [(String, String)] = [
        ("bolt.badge.clock.fill", "Instant AI diagnosis"),
        ("mappin.and.ellipse", "Location-aware routing"),
        ("wrench.and.screwdriver.fill", "Parts price estimates"),
        ("shield.lefthalf.filled", "Safety-first guidance")
    ]
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "What FixSnap offers")
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(features, id: \.1) { feature in
                    FSCard {
                        Image(systemName: feature.0)
                            .font(.system(size: 20))
                            .foregroundStyle(FSColor.flame)
                        Text(feature.1)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct TelegramNetworkSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "The fixer network")
            FSCard {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "paperplane.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(FSColor.teal)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("90+ verified technicians")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Plumbing, electrical and vehicle specialists across the islandget your report the instant it's ready — no waiting on hold.")
                            .font(.system(size: 13))
                            .foregroundStyle(FSColor.textSecondary)
                        HStack(spacing: 8) {
                            FSBadge(text: "Plumbers", tint: FSColor.teal)
                            FSBadge(text: "Electricians", tint: FSColor.flame)
                        }
                        FSBadge(text: "Vehicle mechanics", tint: .white.opacity(0.7))
                    }
                }
            }
        }
    }
}

private struct FooterSection: View {
    var body: some View {
        VStack(spacing: 6) {
            Divider().background(FSColor.stroke)
            Text("FixSnap · AI repair diagnosis, human follow-through")
                .font(.system(size: 11))
                .foregroundStyle(FSColor.textSecondary)
        }
        .padding(.top, 10)
    }
}

private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
