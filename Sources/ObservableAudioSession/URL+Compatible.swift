//
//  URL+Compatible.swift
//
//
//  Created by Chen Hai Teng on 4/10/24.
//

import Foundation

public extension URL {
    static var compatibleTemporary: Self {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            URL.temporaryDirectory
        } else {
            URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        }
    }
    
    func compatibleAppending(path: String, isDirectory: Bool? = nil) -> URL {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            var hint: DirectoryHint = .inferFromPath
            if let isDirectory = isDirectory {
                hint = isDirectory ? .isDirectory : .notDirectory
            }
            return appending(path: path, directoryHint: hint)
        } else {
            if let isDirectory = isDirectory {
                return URL(fileURLWithPath: path, isDirectory: isDirectory, relativeTo: self)
            }
            return URL(fileURLWithPath: path, relativeTo: self)
        }
    }
}
