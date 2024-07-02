//
//  MidiNoteNumber.swift
//  SoundCheck
//
//  Created by Douglas Inglis on 02/07/2024.
//

import Foundation
import AudioKit

let noteFrequencies = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]

extension MIDINoteNumber {
    static func pitchToNoteNumber(pitch: Float) -> MIDINoteNumber {
       
        var frequency = pitch
        
        /* Find the frequency between the bottom and top notes of the octave */
        while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
            frequency /= 2.0
        }
        while frequency < Float(noteFrequencies[0]) {
            frequency *= 2.0
        }
        
        /* Calculate the octave */
        let octave = Int(log2f(pitch / frequency))
        
        var minDistance: Float = 10000.0
        var index = 0

        /* Find the note we're nearest */
        for possibleIndex in 0 ..< noteFrequencies.count {
            let distance = fabsf(Float(noteFrequencies[possibleIndex]) - frequency)
            if distance < minDistance {
                index = possibleIndex
                minDistance = distance
            }
        }
        
        /* Get the midi number from the octave and note */
        return MIDINoteNumber(((octave + 1) * 12) + index);
    }
    
    func toNote() -> String {
        /* Convert back to the note name */
        return "\(noteNamesWithSharps[Int(self) % 12])\(Int(self / 12) - 1)"
    }
}
