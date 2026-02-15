//
//  OperationMode.swift
//  ReplayKitDemo
//
//  Created by Itsuki on 2026/02/15.
//

import Foundation

enum OperationMode: Identifiable {
    case recording
    case capturing
    case clipping
    
    // for updating the camera preview
    var id: UUID {
        return UUID()
    }
}
