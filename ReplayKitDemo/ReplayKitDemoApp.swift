//
//  ReplayKitDemoApp.swift
//  ReplayKitDemo
//
//  Created by Itsuki on 2026/02/14.
//

import SwiftUI

@main
struct ReplayKitDemoApp: App {
    private let screenRecordingManager = ScreenRecordingManager()
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .environment(screenRecordingManager)
            }
        }
    }
}
