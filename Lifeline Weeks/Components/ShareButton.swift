import SwiftUI

struct ShareButton: View {
    let viewModel: LifeViewModel

    @State private var showOptions   = false
    @State private var shareItem:    ShareItem?
    @State private var isGenerating  = false
    @State private var selectedLayout: ShareLayout = .poster

    var body: some View {
        Button {
            showOptions = true
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .confirmationDialog("Share Format", isPresented: $showOptions, titleVisibility: .visible) {
            ForEach(ShareLayout.allCases) { layout in
                Button(layout.rawValue) { generate(layout: layout) }
            }
        }
        .overlay {
            if isGenerating {
                ProgressView().controlSize(.small)
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(image: item.image)
        }
    }

    // MARK: - Generation

    private func generate(layout: ShareLayout) {
        guard !isGenerating else { return }
        isGenerating = true
        Task { @MainActor in
            defer { isGenerating = false }
            let config = ShareConfig(layout: layout)
            guard let image = ShareImageGenerator.generate(
                weeks:               viewModel.weeks,
                progress:            viewModel.progress,
                weeksLived:          viewModel.weeksLived,
                lifeExpectancyYears: viewModel.lifeExpectancy,
                config:              config
            ) else { return }
            shareItem = ShareItem(image: image)
        }
    }
}

// MARK: - Helpers

private struct ShareItem: Identifiable {
    let id  = UUID()
    let image: UIImage
}

private struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
