//
//  AudioCategory.swift
//  ObservableAudioSession
//
//  Created by Chen Hai Teng on 3/26/24.
//

import Foundation
import AVFAudio

public struct AudioCategory : Codable {
    enum KEY: String, CodingKey {
        case category, mode, options
    }
    let category: AVAudioSession.Category
    let mode: AVAudioSession.Mode
    let options: AVAudioSession.CategoryOptions
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: KEY.self)
        self.category = try AVAudioSession.Category(rawValue: container.decode(String.self, forKey: .category))
        self.mode = try AVAudioSession.Mode(rawValue: container.decode(String.self, forKey: .mode))
        self.options = try AVAudioSession.CategoryOptions(rawValue: container.decode(UInt.self, forKey: .options))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: KEY.self)
        try container.encode(category.rawValue, forKey: .category)
        try container.encode(mode.rawValue, forKey: .mode)
        try container.encode(options.rawValue, forKey: .options)
    }
    
    public init(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode = .default, options: AVAudioSession.CategoryOptions = []) {
        self.category = category
        self.mode = mode
        self.options = options
    }
    
    public init?(_ jsonData: Data)  {
        do {
            let decodedCategory = try JSONDecoder().decode(AudioCategory.self, from: jsonData)
            self = decodedCategory
        } catch {
            debugPrint("[AudioCategory] cannot init:\(error.localizedDescription)")
            return nil
        }
    }
}

