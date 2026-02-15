//
//  ContentView.swift
//  ReplayKitDemo
//
//  Created by Itsuki on 2026/02/14.
//

import QuickLook
import SwiftUI
import ReplayKit

struct ContentView: View {

    @Environment(ScreenRecordingManager.self) private var screenRecordingManager

    @State private var showPreviewController: Bool = false

    @State private var clipURL: URL? = nil

    var body: some View {
        @Bindable var screenRecordingManager = screenRecordingManager
        List {

            if let error = screenRecordingManager.error {
                Section {
                    Text(error.localizedDescription)
                        .foregroundStyle(.red)
                }
            }

            if !screenRecordingManager.isAvailable {
                Section {
                    Text("Screen Recorder Not Available")
                        .foregroundStyle(.red)
                }
            }

            Section("Mic & Camera") {

                HStack {
                    Text("Mic Enabled")
                    Toggle(
                        isOn: $screenRecordingManager.isMicrophoneEnabled,
                        label: {}
                    )
                }
                .disabled(screenRecordingManager.isRecording)  // setting it while recording to true will not work on iOS

                HStack {
                    Text("Camera Enabled")
                    Toggle(
                        isOn: $screenRecordingManager.isCameraEnabled,
                        label: {}
                    )
                }
                .disabled(screenRecordingManager.isRecording)  // setting it while recording to true will not work on iOS

                HStack {
                    Text("Camera Position")
                    Picker(
                        selection: $screenRecordingManager.cameraPosition,
                        content: {
                            Text("Front")
                                .tag(RPCameraPosition.front)
                            Text("Back")
                                .tag(RPCameraPosition.back)
                        },
                        label: {}
                    )
                }
            }

            Section {
                if screenRecordingManager.isRecording,
                    let mode = screenRecordingManager.mode
                {
                    switch mode {
                    case .recording:
                        Button(
                            action: {
                                screenRecordingManager.stopRecording()
                            },
                            label: {
                                buttonLabel(
                                    title: "Stop Recording",
                                    subtitle: nil
                                )
                            }
                        )
                    case .capturing:
                        Button(
                            action: {
                                screenRecordingManager.stopCapturing()
                            },
                            label: {
                                buttonLabel(
                                    title: "Stop Capturing",
                                    subtitle: nil
                                )
                            }
                        )
                    case .clipping:
                        Button(
                            action: {
                                screenRecordingManager.generateClip()
                            },
                            label: {
                                buttonLabel(
                                    title: "Export Clip (15sec)",
                                    subtitle: nil
                                )

                            }
                        )
                        .disabled(screenRecordingManager.exportingClip)

                        Button(
                            action: {
                                screenRecordingManager.stopClipBuffering()
                            },
                            label: {
                                buttonLabel(
                                    title: "Stop Clip Buffering",
                                    subtitle: nil
                                )
                            }
                        )
                    }
                } else {
                    Button(
                        action: {
                            screenRecordingManager.startRecording()
                        },
                        label: {
                            buttonLabel(
                                title: "Start Recording",
                                subtitle: "Getting final recording after finish"
                            )
                        }
                    )

                    Button(
                        action: {
                            screenRecordingManager.startCapturing()
                        },
                        label: {
                            buttonLabel(
                                title: "Start Capturing",
                                subtitle: "Getting sampler buffer in real time"
                            )
                        }
                    )

                    Button(
                        action: {
                            screenRecordingManager.startClipBuffering()
                        },
                        label: {
                            buttonLabel(
                                title: "Start Clip Buffering",
                                subtitle: "Generate short (15sec) clip"
                            )
                        }
                    )

                }
            }

            if let cameraPreview = screenRecordingManager.cameraPreviewView {
                Section("Camera") {
                    CameraPreviewViewRepresentable(cameraView: cameraPreview)
                        .frame(width: 400, height: 400, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .listRowBackground(Color.clear)
                        .id(screenRecordingManager.mode?.id)  // to ensure CameraPreviewViewRepresentable is recreated when mode change. Otherwise, the preview will not show up. Another option will be passing in the cameraPreviewView as a binding to the representable, adding it as a subview to an UIView, and update it within updateUIView instead.
                }
            }
        }
        .disabled(!screenRecordingManager.isAvailable)
        .navigationTitle("Replay Kit Demo")
        .onChange(
            of: self.showPreviewController,
            {
                if !showPreviewController {
                    self.screenRecordingManager.recordingPreviewController = nil
                }
            }
        )
        .onChange(
            of: self.screenRecordingManager.recordingPreviewController,
            {
                self.showPreviewController =
                    self.screenRecordingManager.recordingPreviewController
                    != nil
            }
        )
        .sheet(
            isPresented: $showPreviewController,
            content: {
                if let previewController = self.screenRecordingManager
                    .recordingPreviewController
                {
                    ScreenRecordingPreview(controller: previewController)
                        .ignoresSafeArea()
                }
            }
        )
        .quickLookPreview($screenRecordingManager.clipURL)
    }

    @ViewBuilder
    private func buttonLabel(title: String, subtitle: String?) -> some View {
        VStack(
            alignment: .leading,
            content: {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                }
            }
        )
    }
}
