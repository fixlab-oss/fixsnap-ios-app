import SwiftUI
import SafariServices

struct SettingsView: View {
    @State private var showPrivacyPolicy = false

    var body: some View {
        ZStack {
            FSColor.ink.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.top, 8)

                    FSCard {
                        Button {
                            showPrivacyPolicy = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(FSColor.teal)
                                    .frame(width: 24)

                                Text("Privacy Policy")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(FSColor.textSecondary)
                            }
                        }
                    }

                    Text("FixSnap")
                        .font(.system(size: 12))
                        .foregroundStyle(FSColor.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            SafariView(url: URL(string: "https://www.fixsnap.store/privacy-policy")!)
                .ignoresSafeArea()
        }
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
