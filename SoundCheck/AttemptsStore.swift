//
//  AttemptsStore.swift
//  SoundCheck
//
//  Created by Douglas Inglis on 02/07/2024.
//

import Foundation


class AttemptsStore: ObservableObject {
    let defaults = UserDefaults.standard

    @Published var prevAttempts: [Int] = []
    
    
    func logAttempt(numAttempts: Int) {
        let attempts = (defaults.array(forKey: "lastAttempts") ?? []) as! Array<Int>
        var mostRecentAttempts = attempts.count > 9 ? (Array(attempts[..<9]) as! Array<Int>) : attempts
        mostRecentAttempts.insert(numAttempts, at: 0)
        defaults.setValue(mostRecentAttempts, forKey: "lastAttempts")
        prevAttempts = mostRecentAttempts
    }
    
    init() {
        prevAttempts = (defaults.array(forKey: "lastAttempts") ?? []) as! Array<Int>
    }
    
}
