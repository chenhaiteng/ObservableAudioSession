//
//  ObservableAudioSession.swift
//  ObservableAudioSession
//
//  Created by Chen Hai Teng on 3/26/24.
//

import AVFAudio
import Combine

public class ObservableAudioSession : ObservableObject {
    private let tag = "[AudioSession]"
    @Published public private(set) var availableInputs: [AVAudioSessionPortDescription] = []
    @Published public private(set) var outputs: [AVAudioSessionPortDescription] = []
    @Published public private(set) var ready: Bool = false
    
    @Published public private(set) var routeChanged: String? = nil
    
    @Published public private(set) var errorDescription: String? = nil
    
    private let session: AVAudioSession
    private var cancellables = Set<AnyCancellable>()
    
    public init(_ session: AVAudioSession = AVAudioSession.sharedInstance(), category: AudioCategory = AudioCategory(.playAndRecord)) {
        self.session = session
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: self.session)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: self.session)
        Task {
            await setCategory(category)
        }
    }
    
    public func setPreferredInput(_ input: AVAudioSessionPortDescription) {
        guard ready else {
            debugPrint("the session is not ready yet.")
            return
        }
        do {
            try session.setPreferredInput(input)
        } catch {
            debugPrint("set preferred input failed \(error)")
        }
    }
    
    public func setCategory(_ category: AudioCategory) async {
        await session.setup(with: category).receive(on: DispatchQueue.main).sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                debugPrint("\(error)")
                self.errorDescription = error.localizedDescription
            } else {
                debugPrint("session setup success")
            }
        }, receiveValue: { _ in
            self.sessionDidUpdated()
        }).store(in: &cancellables)
    }
    
    public func setCategory(from url: URL) async {
        await session.setup(from: url).receive(on: DispatchQueue.main).sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                debugPrint("\(error)")
                self.errorDescription = error.localizedDescription
            } else {
                debugPrint("session setup success")
            }
        }, receiveValue: { _ in
            self.sessionDidUpdated()
        }).store(in: &cancellables)
    }
    
    @objc func handleRouteChange(notification: Notification) {
        if let obj = notification.object as? AVAudioSession, obj == session {
            self.availableInputs = session.availableInputs ?? []
            self.outputs = session.currentRoute.outputs
            if let code = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt {
                let reason = AVAudioSession.RouteChangeReason(rawValue: code)
                routeChanged = reason?.description ?? "unknown reason"
            } else {
                routeChanged = "unkonwn reason"
            }
        }
    }
    
    @objc func handleInterruption(notification: Notification) {
        debugPrint("system interrupt: \(notification)")
    }
    
    private func sessionDidUpdated() {
        availableInputs = session.availableInputs ?? []
        outputs = session.currentRoute.outputs
        ready = true
    }
}
