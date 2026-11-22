import Foundation
import AVFoundation
import UIKit
import Combine

/// Plays AI replies (backend voice audio or on-device TTS) and can always be stopped.
/// Kept separate from SpeechManager so existing code is untouched.
@MainActor
final class PracticeVoice: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?

    func play(_ data: Data) throws {
        stop()
        try activatePlayback()
        let p = try AVAudioPlayer(data: data)
        player = p
        guard p.play() else {
            throw NSError(domain: "UTalkAudio", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Audio playback could not start."])
        }
    }

    /// On-device text-to-speech fallback.
    func speak(_ text: String, rate: Float = 0.47) {
        stop()
        try? activatePlayback()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        synthesizer.speak(utterance)
    }

    func stop() {
        player?.stop()
        player = nil
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
    }

    private func activatePlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio)
        try session.setActive(true)
    }
}

/// Records one script take to a local file and plays it back.
/// Format: 16 kHz, mono, 16-bit PCM WAV, so the same file can later be fed
/// to the WavLM Core ML model (converted to Float32, windowed to 48,000 samples).
@MainActor
final class ScriptRecorder: NSObject, ObservableObject, AVAudioPlayerDelegate {
    enum Phase { case idle, recording, recorded, playing }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var recordedDuration: TimeInterval = 0
    @Published var errorMessage: String?

    let fileURL: URL
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?

    init(fileName: String = "utalk_script_take.wav") {
        fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        super.init()
    }

    var hasRecording: Bool { phase == .recorded || phase == .playing }

    func startRecording() async {
        guard await AVAudioApplication.requestRecordPermission() else {
            errorMessage = "Please allow microphone access for this app in Settings."
            return
        }
        stopPlayback()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            try? FileManager.default.removeItem(at: fileURL)
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 16_000,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]
            let r = try AVAudioRecorder(url: fileURL, settings: settings)
            guard r.record() else {
                throw NSError(domain: "UTalkAudio", code: 2,
                              userInfo: [NSLocalizedDescriptionKey: "Recording could not start."])
            }
            recorder = r
            errorMessage = nil
            elapsed = 0
            phase = .recording
            timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self, let r = self.recorder else { return }
                    self.elapsed = r.currentTime
                }
            }
        } catch {
            phase = .idle
            errorMessage = "Couldn't start recording: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        guard let r = recorder else { return }
        let length = r.currentTime          // read before stop(); it resets to 0 afterwards
        r.stop()
        recorder = nil
        timer?.invalidate()
        timer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        if length < 0.5 {
            try? FileManager.default.removeItem(at: fileURL)
            recordedDuration = 0
            phase = .idle
            errorMessage = "That take was very short. Tap the mic and try again, no rush."
        } else {
            recordedDuration = length
            phase = .recorded
        }
    }

    /// Deletes the current take.
    func discard() {
        if phase == .recording { stopRecording() }
        stopPlayback()
        try? FileManager.default.removeItem(at: fileURL)
        recordedDuration = 0
        elapsed = 0
        errorMessage = nil
        phase = .idle
    }

    func togglePlayback() {
        if phase == .playing { stopPlayback(); return }
        guard hasRecording else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            let p = try AVAudioPlayer(contentsOf: fileURL)
            p.delegate = self
            guard p.play() else {
                throw NSError(domain: "UTalkAudio", code: 3,
                              userInfo: [NSLocalizedDescriptionKey: "Playback could not start."])
            }
            player = p
            phase = .playing
        } catch {
            errorMessage = "Couldn't play your recording: \(error.localizedDescription)"
        }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        if phase == .playing { phase = .recorded }
    }

    func stopAll() {
        if phase == .recording { stopRecording() }
        stopPlayback()
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.player = nil
            if self.phase == .playing { self.phase = .recorded }
        }
    }
}

/// Looping background sound for a scenario (award show, interrogation room, etc.).
/// Loaded from a Data Set in Assets.xcassets (e.g. "ambience_celebrity"); if it's missing, it stays silent.
/// It fades out before the microphone starts, so it never ends up in recordings or the analysis.
/// Level 0 = off (the player is paused, not just silent, to save battery).
@MainActor
final class AmbiencePlayer: ObservableObject {
    @Published private(set) var isAvailable = false
    private var player: AVAudioPlayer?
    private(set) var level: Float = 0.18

    func load(_ assetName: String?) {
        guard player == nil, let assetName, let asset = NSDataAsset(name: assetName),
              let p = try? AVAudioPlayer(data: asset.data) else { return }
        p.numberOfLoops = -1
        p.volume = 0
        p.prepareToPlay()
        player = p
        isAvailable = true
    }

    /// Changes the volume (0 = off). Resumes playback only if `resumeIfNeeded` (e.g. not while recording).
    func setLevel(_ newLevel: Float, resumeIfNeeded: Bool) {
        level = max(0, min(newLevel, 0.3))       // capped so it never overpowers the voices
        guard let p = player else { return }
        if level <= 0 {
            p.setVolume(0, fadeDuration: 0.3)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 320_000_000)
                if self.level <= 0 { p.pause() }
            }
        } else if resumeIfNeeded {
            resume()
        } else if p.isPlaying {
            p.setVolume(level, fadeDuration: 0.3)
        }
    }

    /// Starts or continues the background sound with a gentle fade-in (does nothing when off).
    func resume() {
        guard let p = player, level > 0 else { return }
        let session = AVAudioSession.sharedInstance()
        if session.category != .playback {
            try? session.setCategory(.playback, mode: .default)
        }
        try? session.setActive(true)
        if !p.isPlaying { p.play() }
        p.setVolume(level, fadeDuration: 0.8)
    }

    /// Fades out and pauses; call (and await) before starting the microphone.
    func fadeOut() async {
        guard let p = player, p.isPlaying else { return }
        p.setVolume(0, fadeDuration: 0.3)
        try? await Task.sleep(nanoseconds: 320_000_000)
        p.pause()
    }

    /// Immediate pause, e.g. when the app goes to the background.
    func pauseNow() {
        player?.pause()
    }

    func stop() {
        player?.stop()
    }
}
