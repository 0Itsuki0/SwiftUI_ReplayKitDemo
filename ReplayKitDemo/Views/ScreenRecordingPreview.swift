//
//  ScreenRecordingPreview.swift
//  ReplayKitDemo
//
//  Created by Itsuki on 2026/02/15.
//

import SwiftUI
import ReplayKit

struct ScreenRecordingPreview: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    var controller: RPPreviewViewController

    func makeUIViewController(context: Context) -> RPPreviewViewController {
        controller.previewControllerDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(
        _ uiViewController: RPPreviewViewController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, RPPreviewViewControllerDelegate {
        var parent: ScreenRecordingPreview
        init(_ parent: ScreenRecordingPreview) {
            self.parent = parent
        }
        func previewControllerDidFinish(
            _ previewController: RPPreviewViewController
        ) {
            Task { @MainActor [weak self] in
                self?.parent.dismiss()
            }
        }
    }
}
