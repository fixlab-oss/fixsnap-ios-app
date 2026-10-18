import SwiftUI
import PhotosUI
import UIKit

struct CaptureFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationService = LocationPermissionService()
    @State private var selectedItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var stage: Stage = .capture
    @State private var report: FaultReport?
    @State private var resultLocation: LocationContext = .unavailable
    @State private var showCamera = false
    @State private var errorMessage: String?
    @State private var description = ""
    @State private var blockingRegionMessage: String?

    private let analysisService = RepairAnalysisService()

    enum Stage { case capture, locating, analyzing, result }

    var body: some View {
        NavigationStack {
            ZStack {
                FSColor.ink.ignoresSafeArea()
                switch stage {
                case .capture: captureStage
                case .locating: loadingStage(title: "Checking your region...", message: "FixSnap is available in Singapore and Sri Lanka.")
                case .analyzing: loadingStage(title: "Analyzing your photo...", message: "Uploading the photo and routing the report through the fixer network.")
                case .result:
                    if let report, let capturedImage {
                        ResultPreview(report: report, image: capturedImage, location: resultLocation)
                    } else {
                        captureStage
                    }
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
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    setImage(image)
                }
                .ignoresSafeArea()
            }
            .alert("Analysis failed", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
            .alert("Region unavailable", isPresented: regionAlertBinding) {
                Button("Start over", role: .cancel) {
                    resetCapture()
                }
            } message: {
                Text(blockingRegionMessage ?? "FixSnap is only available in Singapore and Sri Lanka.")
            }
        }
    }

    private var captureStage: some View {
        VStack(spacing: 18) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(FSColor.card)
                .frame(height: 300)
                .overlay(
                    Group {
                        if let capturedImage {
                            Image(uiImage: capturedImage).resizable().scaledToFill()
                        } else {
                            VStack(spacing: 10) {
                                Image(systemName: "camera.viewfinder")
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

            VStack(spacing: 12) {
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        errorMessage = "Camera is not available in this simulator. Choose a photo from the library or run on a physical device."
                    }
                } label: {
                    Label("Take photo", systemImage: "camera.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(FSColor.teal, in: RoundedRectangle(cornerRadius: 16))
                }

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Choose from library", systemImage: "photo.on.rectangle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(FSColor.card, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FSColor.stroke, lineWidth: 1))
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        await loadPhoto(from: newItem)
                    }
                }
            }
            .padding(.horizontal, 20)

            TextField("Add a short description or address note", text: $description, axis: .vertical)
                .lineLimit(2...4)
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .padding(14)
                .background(FSColor.card, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(FSColor.stroke, lineWidth: 1))
                .padding(.horizontal, 20)

            Text("We check your region first. If location is denied or unavailable, the report is routed to the global fixer group.")
                .font(.system(size: 12))
                .foregroundStyle(FSColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task {
                        await analyzePhoto()
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
                .disabled(capturedImage == nil)
                .opacity(capturedImage == nil ? 0.5 : 1)

                Button("Retake") { resetCapture() }
                    .foregroundStyle(FSColor.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func loadingStage(title: String, message: String) -> some View {
        VStack(spacing: 18) {
            ProgressView()
                .tint(FSColor.teal)
                .scaleEffect(1.4)
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(FSColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private var regionAlertBinding: Binding<Bool> {
        Binding(
            get: { blockingRegionMessage != nil },
            set: { isPresented in
                if !isPresented {
                    blockingRegionMessage = nil
                }
            }
        )
    }

    @MainActor
    private func setImage(_ image: UIImage) {
        capturedImage = image
        report = nil
        stage = .capture
        errorMessage = nil
        blockingRegionMessage = nil
    }

    @MainActor
    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Could not load that photo. Please choose another image."
                return
            }
            setImage(image)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func analyzePhoto() async {
        guard let capturedImage else { return }

        stage = .locating
        errorMessage = nil
        blockingRegionMessage = nil

        let location = await locationService.requestLocationContext()
        resultLocation = location

        if !location.isSupportedRegion {
            stage = .capture
            blockingRegionMessage = "FixSnap is only available in Singapore and Sri Lanka. We detected your location outside our service area."
            return
        }

        stage = .analyzing

        do {
            report = try await analysisService.analyze(
                image: capturedImage,
                location: location,
                description: description
            )
            stage = .result
        } catch {
            stage = .capture
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func resetCapture() {
        capturedImage = nil
        selectedItem = nil
        report = nil
        resultLocation = .unavailable
        description = ""
        stage = .capture
        errorMessage = nil
        blockingRegionMessage = nil
    }
}

#Preview {
    CaptureFlowView()
}
