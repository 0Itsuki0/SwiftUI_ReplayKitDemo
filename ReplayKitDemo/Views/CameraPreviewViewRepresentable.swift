//
//  CameraPreviewViewRepresentable.swift
//  ReplayKitDemo
//
//  Created by Itsuki on 2026/02/15.
//

import SwiftUI

struct CameraPreviewViewRepresentable: UIViewRepresentable {
    var cameraView: UIView
    func makeUIView(context: Context) -> UIView {
        return cameraView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
