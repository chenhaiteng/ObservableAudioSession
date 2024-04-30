//
//  AVAudioSession+Ext.swift
//  ObservableAudioSession
//
//  Created by Chen Hai Teng on 3/26/24.
//

import Foundation
import AVFAudio
import Combine


public enum AVAudioSessionFail: Error {
    case decode(String)
    case activate(String)
    
    var localizedDescription: String {
        switch self {
        case .activate(let reason):
            return NSLocalizedString("activate: \(reason)", comment: "")
        case .decode(let reason):
            return NSLocalizedString("decode: \(reason)", comment: "")
        }
    }
}

public extension AVAudioSession {
    private func readCategory(from url: URL) async -> AudioCategory? {
        do {
            let data = try Data(contentsOf: url)
            return AudioCategory(data)
        } catch {
            debugPrint("[AudioCategory] \(error.localizedDescription)")
            return nil
        }
    }
    
    private func readCategory(from data: Data) async -> AudioCategory? {
        return AudioCategory(data)
    }
    
    /// setup a AVAudioSession from url.
    /// the content of url should be json data of the AudioCategory.
    func setup(from url: URL) async -> Future<AVAudioSession, AVAudioSessionFail> {
        if let category = await self.readCategory(from: url) {
            return await self.setup(with: category)
        } else {
            return Future {
                throw AVAudioSessionFail.activate("cannot create category from  url: \(url)")
            }
        }
    }
    
    /// setup a AVAudioSession from the json data of AudioCategory.
    func setup(from data: Data) async -> Future<AVAudioSession, AVAudioSessionFail> {
        if let category = await self.readCategory(from: data) {
            return await self.setup(with: category)
        } else {
            return Future {
                throw AVAudioSessionFail.activate("cannot create category from data")
            }
        }
    }
    
    /// setup a AVAudioSession from AudioCategory
    func setup(with category: AudioCategory) async -> Future<AVAudioSession, AVAudioSessionFail> {
        Future {
            let sessionCategory = try self.check(category: category.category)
            guard self.availableModes.contains(category.mode) else {
                let verbose = "The mode \(category.mode.rawValue) is unavailable on this device."
                debugPrint("[AudioSession]" + verbose)
                throw AVAudioSessionFail.activate(verbose)
            }
            try self.setCategory(sessionCategory, mode: category.mode, options: category.options)
            try self.setActive(true)
            return self
        }
    }
    
    func check(category: Category) throws -> Category {
        guard self.availableCategories.contains(category) else {
            let verbose = "The category \(category.rawValue) is unavailable on this device."
            debugPrint("[AudioSession]" + verbose)
            throw AVAudioSessionFail.activate(verbose)
        }
        return category
    }
    
    func set(category: Category) throws {
        guard category != self.category else { return }
        try setCategory(check(category: category))
    }
}

extension AVAudioSession.RouteChangeReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .newDeviceAvailable:
            return "A new device became available."
        case .oldDeviceUnavailable:
            return "An old device became unavailable."
        case .categoryChange:
            return "The audio category has changed."
        case .override:
            return "The route has been overridden."
        case .wakeFromSleep:
            return "The device woke from sleep."
        case .noSuitableRouteForCategory:
            return "There is no route for the current category"
        case .routeConfigurationChange:
            return "Configuration has changed."
        case .unknown:
            return "The reason is unknown."
        @unknown default:
            return "The reason is unknown."
        }
    }
}
