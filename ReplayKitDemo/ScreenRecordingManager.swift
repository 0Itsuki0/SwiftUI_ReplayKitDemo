//
//  ScreenRecordingManager.swift
//  ReplayKitDemo
//
//  Created by Itsuki on 2026/02/15.
//

import ReplayKit
import SwiftUI

// `startCapture` need to be called in a nonisolated context, otherwise the app with crash
@Observable
nonisolated class ScreenRecordingManager: NSObject, @unchecked Sendable {
    private(set) var mode: OperationMode?

    private(set) var exportingClip: Bool = false

    // MARK: - get only properties from the recorder

    // A Boolean value that indicates whether the screen recorder is available for recording.
    private(set) var isAvailable: Bool
    // A Boolean value that indicates whether the app is currently recording.
    private(set) var isRecording: Bool

    // MARK: - Property for configurations and results
    var error: Error?

    // available when recording finished
    var recordingPreviewController: RPPreviewViewController?

    // A view containing the contents of the front-facing camera.
    // When the value in the isCameraEnabled property is true, this property contains a view with the live camera view
    var cameraPreviewView: UIView?

    var clipURL: URL?

    // A Boolean value that indicates whether the microphone is currently enabled.
    var isMicrophoneEnabled: Bool = false {
        didSet {
            recorder.isMicrophoneEnabled = isMicrophoneEnabled
        }
    }
    // A Boolean value that indicates whether the camera is currently enabled.
    // The default value of this property is false. Set this property to true to enable the camera.
    // this property is key-value observable.
    var isCameraEnabled: Bool = false {
        didSet {
            recorder.isCameraEnabled = isCameraEnabled
            self.cameraPreviewView = recorder.cameraPreviewView
        }
    }

    // The camera position to use.
    // The default value of this property is AVCaptureDevice.Position.front.
    // this property is key-value observable.
    var cameraPosition: RPCameraPosition = .front {
        didSet {
            recorder.cameraPosition = cameraPosition
        }
    }

    private let recorder = RPScreenRecorder.shared()

    override init() {
        self.isAvailable = recorder.isAvailable
        self.isRecording = recorder.isRecording
        super.init()
        self.recorder.delegate = self
    }

    // MARK: - Recording
    // Starts screen, video and audio recording
    func startRecording() {
        guard self.isAvailable, !self.isRecording else {
            return
        }
        recorder.startRecording(handler: { [weak self] in
            self?.error = $0
            self?.isRecording = $0 == nil
            self?.mode = $0 == nil ? .recording : nil
            self?.cameraPreviewView = self?.recorder.cameraPreviewView
        })
    }

    // Stop recording
    func stopRecording() {
        guard self.isRecording else {
            return
        }

        recorder.stopRecording(handler: { [weak self] controller, error in
            self?.cleanUp(screenRecorder: self?.recorder, error: error)
            // assign controller after clean up
            self?.recordingPreviewController = controller
        })

    }

    // MARK: - Capturing
    // Starts screen, video and audio capture (real time data so that it can be streamed to others)
    func startCapturing() {
        guard self.isAvailable, !self.isRecording else {
            return
        }

        // `startCapture` need to be called in a nonisolated context, otherwise the app with crash
        recorder.startCapture(
            handler: { sampleBuffer, sampleBufferType, error in
                // The sample calls this handler every time ReplayKit is ready to give you a video, audio or microphone sample.
                // You need to check several things here so that you can process these sample buffers correctly.
                // Check for an error and, if there is one, print it.
                if let error {
                    self.error = error
                    return
                }

                // Process the buffer based on its type,
                // for example, streaming those to the server
                switch sampleBufferType {
                case .video:
                    print("video")
                    break
                case .audioApp:
                    print("audioApp")
                    break
                case .audioMic:
                    print("audioMic")
                default:
                    print("Unable to process sample buffer")
                }
            },
            completionHandler: { [weak self] in
                self?.error = $0
                self?.isRecording = $0 == nil
                self?.mode = $0 == nil ? .capturing : nil
                self?.cameraPreviewView = self?.recorder.cameraPreviewView
            }
        )
    }

    // stop capturing
    func stopCapturing() {
        guard self.isRecording else {
            return
        }
        recorder.stopCapture(handler: { [weak self] error in
            self?.cleanUp(screenRecorder: self?.recorder, error: error)
        })
    }

    // MARK: - Clips

    // start buffering a clip recording
    func startClipBuffering() {
        guard self.isAvailable, !self.isRecording else {
            return
        }
        recorder.startClipBuffering(completionHandler: { [weak self] in
            self?.error = $0
            self?.isRecording = $0 == nil
            self?.mode = $0 == nil ? .clipping : nil
            self?.cameraPreviewView = self?.recorder.cameraPreviewView
        })
    }

    // Stops buffering a clip recording.
    func stopClipBuffering() {
        guard self.isRecording else {
            return
        }
        recorder.stopClipBuffering(completionHandler: { [weak self] error in
            self?.cleanUp(screenRecorder: self?.recorder, error: error)
        })
    }

    // generate a clip if we are already recording / capturing
    func generateClip() {
        guard self.isRecording, !self.exportingClip else {
            return
        }
        exportingClip = true
        let durationSec = TimeInterval(15)
        let url = URL.temporaryDirectory.appending(
            path: "\(UUID().uuidString).mp4"
        )
        recorder.exportClip(
            to: url,
            duration: durationSec,
            completionHandler: { [weak self] error in
                self?.error = error
                self?.exportingClip = false
                if error == nil {
                    self?.clipURL = url
                }
            }
        )
    }
}

// Set the delegate to respond to changes by the recorder; for example, when the recording stops.
nonisolated extension ScreenRecordingManager: RPScreenRecorderDelegate {
    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder)
    {
        self.cleanUp(screenRecorder: screenRecorder, error: error)
    }

    // This method is called when recording stops due to an error or a change in recording availability. If any part of the stopped recording is available, an instance of RPPreviewViewController is returned.
    // NOT due to a call of stopRecording
    func screenRecorder(
        _ screenRecorder: RPScreenRecorder,
        didStopRecordingWith previewViewController: RPPreviewViewController?,
        error: (any Error)?
    ) {
        self.recordingPreviewController = previewViewController
        self.cleanUp(screenRecorder: screenRecorder, error: error)
    }

    private func cleanUp(screenRecorder: RPScreenRecorder?, error: Error?) {
        if let screenRecorder {
            self.isAvailable = screenRecorder.isAvailable
        }
        self.error = error
        self.isRecording = false
        self.cameraPreviewView = nil
        self.recordingPreviewController = nil
        self.mode = nil
    }
}
