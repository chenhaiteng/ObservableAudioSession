//
//  ObservablePlayer.swift
//
//
//  Created by Chen Hai Teng on 4/9/24.
//

import Foundation
import Combine
import AVFAudio

enum AVAudioPlayerFail : Error {
    case create(String)
}

extension AVAudioPlayer {
    static func createPlayer(url: URL) -> Future<AVAudioPlayer, AVAudioPlayerFail> {
        Future { promise in
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                promise(.success(player))
            } catch {
                promise(.failure(.create(error.localizedDescription)))
            }
        }
    }
}

public class ObservablePlayer: NSObject, ObservableObject {
    private static let meteringPeriod = 0.1
    private var player : AVAudioPlayer? = nil
    private var cancellables = Set<AnyCancellable>()
    
    @Published public var ready: Bool = false
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: TimeInterval = 0.0
    public var duration: TimeInterval {
        player?.duration ?? 0.0
    }
    
    private let meteringQueue = DispatchQueue.global(qos: .default)
    private let timer = Timer.publish(every: meteringPeriod, on: .main, in: .common).autoconnect()
    private var meteringTimer: AnyCancellable? = nil
    
    public func clean() {
        if let player = player, player.isPlaying {
            player.stop()
        }
        isPlaying = false
        ready = false
        player = nil
    }
    
    public func prepare(url: URL) {
        clean()
        AVAudioPlayer.createPlayer(url: url).receive(on: RunLoop.main).sink(receiveCompletion: { result in
            if case .failure(let failure) = result {
                debugPrint(failure.localizedDescription)
            }
        }, receiveValue: { player in
            player.delegate = self
            self.player = player
            self.ready = true
        }).store(in: &cancellables)
    }
    
    public func play(loop: Bool = false) {
        if let player = player, !player.isPlaying {
            player.numberOfLoops = loop ? -1 : 0
            isPlaying = player.play()
            meteringTimer = timer.receive(on: meteringQueue).sink(receiveValue: { _ in
                player.updateMeters()
                DispatchQueue.main.async {
                    self.currentTime = player.currentTime
                }
            })
        }
    }
    
    public func stop() {
        if let player = player, player.isPlaying {
            player.stop()
            meteringTimer?.cancel() // stop publish
            player.currentTime = 0
            currentTime = player.currentTime // reset published current time to 0.0
            isPlaying = player.isPlaying
        }
    }
}

extension ObservablePlayer: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            debugPrint("[Player] did finish playing.")
            self.isPlaying = false
            self.meteringTimer?.cancel()
        }
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        debugPrint("[Player] decode error:"
                    + String(describing: error?.localizedDescription))
    }
}
