//
//  Future+Concurrency.swift
//  
//
//  Created by Chen Hai Teng on 3/27/24.
//

import Combine

/// Use try-await to instead of GCD to co-work with Future
extension Future where Failure: Error {
    convenience init(asyncFunc: @escaping () async throws -> Output) {
        self.init { promise in
            Task {
                do {
                    let result = try await asyncFunc()
                    promise(.success(result))
                } catch {
                    promise(.failure(error as! Failure))
                }
            }
        }
    }
}

