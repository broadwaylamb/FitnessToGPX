//
//  Utils.swift
//  FitnessToGPX
//
//  Created by Sergej Jaskiewicz on 03.02.2022.
//

import os

func with<T>(_ value: T, _ body: (inout T) -> Void) -> T {
    var value = value
    body(&value)
    return value
}

typealias Logger = os.Logger

extension Logger {
    init(category: String) {
        self.init(subsystem: FitnessToGPXApp.bundleIdentifier, category: category)
    }
}
