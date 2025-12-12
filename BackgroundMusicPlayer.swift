//
//  BackgroundMusicPlayer.swift
//  Upcycled 2045
//
//  Created by Rivian Pratama on 23/02/25
//

import AVFoundation

class BackgroundMusicPlayer {
    static let shared = BackgroundMusicPlayer()
    
    private var audioPlayer: AVAudioPlayer?
    private var soundEffects: [String: AVAudioPlayer] = [:]

    private init() {
        loadAudioPlayer(for: "backgroundSong", loop: true)

        let soundEffectFiles = [
            "buttonClick", "confirmClick", "dailyReport", "fabricateClick",
            "materialClick", "modelClick", "pageChanging", "resetClick",
            "sellClick", "shopClick", "storeOpen", "storeClose"
        ]
        
        for sound in soundEffectFiles {
            loadAudioPlayer(for: sound, loop: false)
        }
    }

    private func loadAudioPlayer(for name: String, loop: Bool) {
        var url: URL?

        url = Bundle.main.url(forResource: name, withExtension: "mp3")
        if url == nil {
            url = Bundle.main.url(forResource: name, withExtension: "wav")
        }
        
        if let validURL = url {
            do {
                let player = try AVAudioPlayer(contentsOf: validURL)
                player.prepareToPlay()
                player.numberOfLoops = loop ? -1 : 0
                if loop {
                    audioPlayer = player
                } else {
                    soundEffects[name] = player
                }
            } catch {
                print("Error loading \(name): \(error.localizedDescription)")
            }
        } else {
            print("❌ \(name) sound file not found in bundle.")
        }
    }

    func play() {
        if audioPlayer?.isPlaying == false {
            audioPlayer?.play()
        }
    }

    func playSoundEffect(_ name: String) {
        if let player = soundEffects[name] {
            player.currentTime = 0 // Restart sound if retriggered
            player.play()
        } else {
            print("⚠️ Sound effect '\(name)' not found in loaded audio files.")
        }
    }
}
