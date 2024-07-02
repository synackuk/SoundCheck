//
//  SoundCheckApp.swift
//  SoundCheck
//
//  Created by Douglas Inglis on 01/07/2024.
//

import SwiftUI
import AVFAudio
import AudioKit
import AVFoundation

@main
struct SoundCheckApp: App {
    init() {
        #if os(iOS)
            do {
                Settings.bufferLength = .short
                try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(Settings.bufferLength.duration)
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord,
                                                                options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let err {
                print(err)
            }
        #endif
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
