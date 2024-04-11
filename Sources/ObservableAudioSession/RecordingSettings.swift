//
//  RecordingSettings.swift
//  AudioRecordingPrototype
//
//  Created by Chen Hai Teng on 3/13/24.
//

import Foundation
import AVFAudio

enum RecordingSettings {
    static let pcmStereo: [String: Any] =
    [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVLinearPCMIsNonInterleaved: false,
        AVSampleRateKey: 44_100.0,
        AVNumberOfChannelsKey: 2,
        AVLinearPCMBitDepthKey: 16,
        "filetype": "wav"
    ]
    
    static let pcmMono: [String: Any] =
    [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVLinearPCMIsNonInterleaved: false,
        AVSampleRateKey: 44_100.0,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        "filetype": "wav"
    ]
    
    static let aacStereo: [String: Any] =
    [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVLinearPCMIsNonInterleaved: false,
        AVSampleRateKey: 44_100.0,
        AVNumberOfChannelsKey: 2,
        AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        "filetype": "aac"
    ]
    
    static let aacMono: [String: Any] =
    [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.medium,
        "filetype": "aac"
    ]
}
