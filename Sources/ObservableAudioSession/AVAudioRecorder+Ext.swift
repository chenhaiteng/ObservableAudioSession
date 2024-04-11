//
//  AVAudioRecorder+Ext.swift
//
//
//  Created by Chen Hai Teng on 4/10/24.
//

import Foundation
import AVFAudio
import Combine
import ObservableAudioSession

public enum AVAudioRecorderFail: Error {
    case create(String)
}

extension AVAudioRecorder {
    @discardableResult func delegate(to delegate: AVAudioRecorderDelegate) -> AVAudioRecorder {
        self.delegate = delegate
        return self
    }
    
    @discardableResult func enableMetering(_ enabled: Bool) -> AVAudioRecorder {
        isMeteringEnabled = enabled
        return self
    }
    
    func prepare() -> Future<Bool, Never> {
        Future { [unowned self] promise in
            DispatchQueue.global(qos: .utility).async {
                promise(.success(self.prepareToRecord()))
            }
        }
    }
    
}

public extension AVAudioRecorder {
    static func createRecorder(url: URL? = nil, settings:[String: Any]) throws -> AVAudioRecorder {
        let recordingUrl = url ?? URL.compatibleTemporary.compatibleAppending(path: "recording." + ((settings["filetype"] as? String) ?? ""))
        return try AVAudioRecorder(url:recordingUrl, settings: settings).enableMetering(true)
    }
    
    static func prepareRecorder(url: URL? = nil, settings:[String: Any]) -> Future<AVAudioRecorder, AVAudioRecorderFail> {
        Future { promise in
            do {
                let recorder = try createRecorder(url: url, settings: settings)
                promise(.success(recorder))
            } catch {
                promise(.failure(.create(error.localizedDescription)))
            }
        }
    }
    
    static func preparePCMRecorder(url: URL? = nil) -> Future<AVAudioRecorder, AVAudioRecorderFail> {
        Future { promise in
            do {
                let recorder = try pcmRecorder(url: url)
                promise(.success(recorder))
            } catch {
                promise(.failure(.create(error.localizedDescription)))
            }
        }
    }
    
    static func pcmRecorder(url: URL? = nil) throws -> AVAudioRecorder {
        return try createRecorder(url:url, settings: RecordingSettings.pcmStereo).enableMetering(true)
    }
}
