//
//  ObservableRecorder.swift
//
//
//  Created by Chen Hai Teng on 4/10/24.
//

import Foundation
import Combine
import AVFAudio

public struct AVAudioMetering : Equatable {
    let numOfChannels: Int
    var peak: [Float]
    var average: [Float]
    init(numOfChannels: Int) {
        self.numOfChannels = numOfChannels
        self.peak = [Float](repeating: 0.0, count: numOfChannels)
        self.average = [Float](repeating: 0.0, count: numOfChannels)
    }
}

public class ObservableRecorder : NSObject, ObservableObject {
    
    private var recorder : AVAudioRecorder? = nil
    private var cancellables = Set<AnyCancellable>()
    @Published public var recordingResult: Bool = false
    @Published public var ready: Bool = false
    @Published public var isRecording: Bool = false
    
    @Published public var meteringData: AVAudioMetering? = nil
    
//    private var settings: [String: Any]
    public var resultUrl: URL? {
        recorder?.url
    }
    
    private let meteringQueue = DispatchQueue.global()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var meteringTimer: AnyCancellable? = nil
    
    public func record() -> Bool {
        guard let recorder = recorder else { return false }
        guard !recorder.isRecording else { return true }
        recordingResult = false // reset recordingResult
        if recorder.record() {
            meteringTimer = timer.receive(on: meteringQueue).sink(receiveValue: { [weak self] _ in
                recorder.updateMeters()
                var newData = AVAudioMetering(numOfChannels: (recorder.settings[AVNumberOfChannelsKey] as? Int) ?? 1)
                for i in 0..<newData.numOfChannels {
                    newData.average[i] = recorder.averagePower(forChannel: i)
                    newData.peak[i] = recorder.peakPower(forChannel: i)
                }
                DispatchQueue.main.async {
                    if let self = self {
                        self.meteringData = newData
                    }
                }
            })
            isRecording = recorder.isRecording
            return true
        }
        return false
    }
    
    public func record(forDuration duration: TimeInterval) {
        if let recorder = recorder,
            !recorder.isRecording,
            recorder.record(forDuration: duration) {
            isRecording = true
        }
    }

    public func stop() {
        if let recorder = recorder, recorder.isRecording {
            recorder.stop()
            isRecording = false
            meteringTimer?.cancel()
            meteringTimer = nil
        }
    }
    
    public func pause() {
        if let recorder = recorder, recorder.isRecording {
            recorder.pause()
            isRecording = recorder.isRecording
        }
    }
    
    public func reset(with settings: [String: Any]) {
        stop()
        recorder = nil
        ready = false
        recordingResult = false
        
        AVAudioRecorder.prepareRecorder(settings: settings).receive(on: DispatchQueue.main).sink { result in
            if case .failure(let error) = result {
                debugPrint("[AVAudioRecorder]" + error.localizedDescription)
                self.recorder = nil
            } else {
                debugPrint("[AVAudioRecorder] prepared")
            }
        } receiveValue: { recorder in
            self.recorder = recorder
            self.recorder?.delegate = self
            self.ready = true
            debugPrint("[AVAudioRecorder] prepared and assigned")
        }.store(in: &cancellables)
    }
    
    deinit {
        if let recorder = recorder, recorder.isRecording {
            recorder.stop()
        }
        recorder = nil
    }
}

extension ObservableRecorder : AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        if flag, FileManager.default.fileExists(atPath: recorder.url.path()) {
            recordingResult = true
        } else {
            recordingResult = false
        }
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        debugPrint("[AVAudioRecorer] " + (error?.localizedDescription ?? "unkonwn"))
        recordingResult = false
    }
}
