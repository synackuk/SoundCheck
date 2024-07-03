//
//  GameView.swift
//  SoundCheck
//
//  Created by Douglas Inglis on 02/07/2024.
//

import SoundpipeAudioKit
import AudioKitEX
import AudioKit
import SwiftUI

struct GameData {
    var higherOrLower = ""
    var noteName = ""
    var targetNote: MIDINoteNumber = 0
    var wrongNotes = 0
}


class GameManager: ObservableObject {
    @Published var data = GameData()
    @Published var attemptsInfo = AttemptsStore()
    
    let instruments = ["Piano"];
    
    var sequencer: SequencerTrack!

    let listenEngine = AudioEngine()
    let TalkEngine = AudioEngine()

    let initialDevice: Device
    var instrument = AppleSampler()
    var midiCallback: CallbackInstrument!
    

    let mic: AudioEngine.InputNode
    var realOut: Fader?
    let silence: Fader


    var tracker: PitchTap!
    
    func playNote() {
        
        /* Disable tracking while we're playing the note */
        self.listenEngine.stop()
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            /* Run the sequence */
            self.sequencer?.playFromStart()

            while(self.sequencer.isPlaying) {
                sleep(1)
            }
            sleep(1)

            try! self.listenEngine.start()
        }
        
    }
    
    func newRound() {
        
        data.targetNote = MIDINoteNumber.random(in: 40...76)
        
        /* Re-set the sequencer */
        sequencer.clear()
        sequencer.add(noteNumber: data.targetNote, position: 0.0, duration: 2)

        
        /* Select a new instrument */
        do {
            if let fileURL = Bundle.main.url(forResource: instruments.randomElement(), withExtension: "sf2") {

                try instrument.loadInstrument(at: fileURL)
            } else {
                Log("Could not find file")
            }

        } catch {
            Log("Could not load instrument")
        }
        
        
        
        playNote()
    }

    init() {
        /* Initialise the inputs */
        guard let input = listenEngine.input else { fatalError() }
        guard let device = listenEngine.inputDevice else { fatalError() }

        initialDevice = device

        mic = input
        silence = Fader(mic, gain: 0)

        
        midiCallback = CallbackInstrument { status, note, vel in
            if status == 144 {
                /* Play the new note */
                self.instrument.play(noteNumber: note, channel: 0)
            } else if status == 128 {
                for i in 0...127 {
                    /* Kill the notes */
                    self.instrument.stop(noteNumber: MIDINoteNumber(i), channel: 0)
                }
            }
        }
        
        /* Set outputs */
        TalkEngine.output = Fader(PeakLimiter(Mixer(instrument, midiCallback), attackTime: 0.001, decayTime: 0, preGain: 0))
        listenEngine.output = silence
                

        /* Setup the tracker */
        tracker = PitchTap(mic) { pitch, amp in
            DispatchQueue.main.async {
                self.update(pitch[0], amp[0])
            }
        }
        
        tracker.start()

        sequencer = SequencerTrack(targetNode: midiCallback)
        sequencer.length = 2.01
        sequencer.loopEnabled = false

        newRound()

        
    }

    func update(_ pitch: AUValue, _ amp: AUValue) {
        
        /* Try to cut out background noise */
        guard amp > 0.2 else { return }
        
        /* Get the midi note number */
        let guess = MIDINoteNumber.pitchToNoteNumber(pitch: pitch)
        
        if(data.noteName == guess.toNote()) {
            return
        }
        
        /* Get the midi note name */
        data.noteName = guess.toNote()

        
        if(guess == data.targetNote) {
            attemptsInfo.logAttempt(numAttempts: data.wrongNotes)
            data.higherOrLower = ""
            data.wrongNotes = 0
            data.noteName = ""
            newRound()
            return
        }
        
        data.wrongNotes += 1
        
        if(guess > data.targetNote) {
            data.higherOrLower = "Too high!"
            return
        }
        data.higherOrLower = "Too low!"

    }
}


struct GameView: View {
    @StateObject var manager = GameManager()
    
    
    @State var blur = true
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Mistakes: \(manager.data.wrongNotes)")
                .font(.subheadline)
                .opacity(manager.data.wrongNotes > 0 ? 1 : 0)

            
            Circle()
                .fill(Color(.secondarySystemFill))
                .frame(maxHeight:200)
                .overlay {
                    Text(manager.data.noteName).font(.system(size: 60))
                }

            Button(action: {manager.playNote()}, label: {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Replay sound").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                }
            })
            
            HStack {
                Spacer()
                Text("\(manager.data.higherOrLower)").opacity(blur ? 0 : 1)
                    .font(.title2)
                Spacer()
                Button(action: {
                    blur = false
                }, label: {
                    Text("Show hint")
                        .font(.title2)
                })
                .opacity(manager.data.higherOrLower == "" ? 0 : 1)
                Spacer()
            }
            .padding(.top)
            .padding(.horizontal)
            .onChange(of: manager.data.noteName, {
                blur = true
            })
            Spacer()

        }
        .onAppear {
            try? manager.TalkEngine.start()
            try?  manager.listenEngine.start()
        }
        .onDisappear {
            manager.TalkEngine.stop()
            manager.listenEngine.stop()
        }
    }
}

#Preview {
    GameView()
}
