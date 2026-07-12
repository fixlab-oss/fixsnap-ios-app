import SwiftUI
import PhotosUI

struct CaptureFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var previewImage: Image?
    @State private var stage: Stage = .capture

    enum Stage { case capture, analyzing, result }

    var body: some View {
        NavigationStack {
            ZStack {
                FSColor.ink.ignoresSafeArea()
                switch stage {
                case .capture: captureStage
                case .analyzing: analyzingStage
                case .result: ResultPreview()
                }
            }
            .navigationTitle(stage == .capture ? "Capture a fault" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .tint(.white)
                }
            }
        }
    }

    private var captureStage: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(FSColor.card)
                .frame(height: 320)
                .overlay(
                    Group {
                        if let previewImage {
                            previewImage.resizable().scaledToFill()
                        } else {
                            VStack(spacing: 10) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundStyle(FSColor.textSecondary)
                                Text("No photo yet")
                                    .foregroundStyle(FSColor.textSecondary)
                            }
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(FSColor.stroke, lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.top, 20)

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Choose from library", systemImage: "photo.on.rectangle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(FSColor.card, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(FSColor.stroke, lineWidth: 1))
            }
            .padding(.horizontal, 20)
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        previewImage = Image(uiImage: uiImage)
                    }
                }
            }

            Text("Camera capture requires a physical device. Use the photo library here to preview the flow.")
                .font(.system(size: 12))
                .foregroundStyle(FSColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    stage = .analyzing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        stage = .result
                    }
                } label: {
                    Text("Analyze & route to fixers")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(colors: [FSColor.teal, FSColor.flame], startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                }
                .disabled(previewImage == nil)
                .opacity(previewImage == nil ? 0.5 : 1)

                Button("Retake") { previewImage = nil; selectedItem = nil }
                    .foregroundStyle(FSColor.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private var analyzingStage: some View {
        VStack(spacing: 18) {
            ProgressView()
                .tint(FSColor.teal)
                .scaleEffect(1.4)
            Text("Analyzing your photo…")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
            Text("Checking your region and consulting the AI diagnosis model.")
                .font(.system(size: 13))
                .foregroundStyle(FSColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    CaptureFlowView()
}
