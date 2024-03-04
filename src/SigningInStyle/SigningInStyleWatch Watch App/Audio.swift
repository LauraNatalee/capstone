//
//  Audio.swift
//  SigningInStyleWatch Watch App
//
//  Created by Simone Ocvirk on 2024-01-20.
//
import AVFoundation
import UIKit

class Speaker {
    let speechSynthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.playback,
                                mode: .default,
                                policy: .default,
                                options: [])
            session.activate(options: []) { (success, error) in
                if let err = error {
                    print(err)
                } else { self.speechSynthesizer.speak(utterance) }
            }
        } catch {
            print(error)
        }
    }
    
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}
