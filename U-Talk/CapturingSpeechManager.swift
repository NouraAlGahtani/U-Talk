import Foundation
import Speech
import AVFoundation
import Combine

/// Same speech-to-text behavior as SpeechManager (on-device, partial results),
/// but it also saves each answer as a 16 kHz mono WAV so the WavLM model and
/// the pause analysis can run on conversation speech. SpeechManager is left unchanged. last update
@MainActor
final class CapturingSpeechManager: ObservableObject {
    @Published var transcript = ""
    @Published var listening = false
    @Published var errorMessage: String?

    /// One file per kept answer, in order.
    private(set) var turnFiles: [URL] = []

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var tapInstalled = false
    private var sessionID = UUID()
    private var writer: TurnAudioWriter?
    private var currentFile: URL?
    private let conversationID = UUID().uuidString.prefix(8)

    func authorize() async -> Bool {
        let speechAllowed = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        let micAllowed = await AVAudioApplication.requestRecordPermission()
        if !speechAllowed || !micAllowed {
            errorMessage = "Please enable Microphone and Speech Recognition permissions in Settings."
        }
        return speechAllowed && micAllowed
    }

    func start() async {
        guard await authorize() else { return }
        stop()
        errorMessage = nil
        transcript = ""
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognition is currently unavailable. Please try again."
            return
        }

        let currentID = UUID()
        sessionID = currentID
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                throw NSError(domain: "UTalkSpeech", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "No usable microphone input format was found."])
            }

            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            req.taskHint = .dictation
            if recognizer.supportsOnDeviceRecognition {
                req.requiresOnDeviceRecognition = true
            }
            request = req

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("utalk_conv_\(conversationID)_turn\(turnFiles.count + 1).wav")
            try? FileManager.default.removeItem(at: url)
            let turnWriter = try TurnAudioWriter(url: url, inputFormat: format)
            writer = turnWriter
            currentFile = url

            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                req.append(buffer)
                turnWriter.append(buffer)
            }
            tapInstalled = true
            engine.prepare()
            try engine.start()
            listening = true

            task = recognizer.recognitionTask(with: req) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self, self.sessionID == currentID else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    if let error {
                        let nsError = error as NSError
                        self.stop()
                        self.discardLastTurn()      // not sent as an answer, so not analyzed
                        if nsError.code == 1110 && nsError.domain == "kAFAssistantErrorDomain" {
                            self.errorMessage = "No speech was recognized this time. Tap the microphone to try again, and take your time."
                        } else {
                            self.errorMessage = "Speech recognition error: \(error.localizedDescription) (\(nsError.domain): \(nsError.code))"
                        }
                    } else if result?.isFinal == true {
                        self.stop()
                        self.discardLastTurn()      // not sent as an answer, so not analyzed
                    }
                }
            }
        } catch {
            stop()
            let nsError = error as NSError
            errorMessage = "Couldn't start recording: \(error.localizedDescription) (\(nsError.domain): \(nsError.code))"
        }
    }

    /// Stops listening. The answer's audio file is kept until `discardLastTurn()` is called.
    func stop() {
        sessionID = UUID()
        if engine.isRunning { engine.stop() }
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        listening = false

        if let writer, let url = currentFile {
            let seconds = writer.close()
            if seconds > 0 { turnFiles.append(url) } else { try? FileManager.default.removeItem(at: url) }
        }
        writer = nil
        currentFile = nil
    }

    /// Call when an answer is not used (e.g. nothing was recognized), so it isn't analyzed.
    func discardLastTurn() {
        guard let last = turnFiles.popLast() else { return }
        try? FileManager.default.removeItem(at: last)
    }
}

/// Converts microphone buffers to 16 kHz mono and writes them to a 16-bit PCM WAV.
/// Called on the audio thread; a lock protects it against `close()` from the main thread.
final class TurnAudioWriter {
    private let lock = NSLock()
    private var file: AVAudioFile?
    private let converter: AVAudioConverter
    private let outFormat: AVAudioFormat
    private var framesWritten: AVAudioFramePosition = 0

    init(url: URL, inputFormat: AVAudioFormat) throws {
        guard let out = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16_000, channels: 1, interleaved: false),
              let conv = AVAudioConverter(from: inputFormat, to: out) else {
            throw NSError(domain: "UTalkAudio", code: 10,
                          userInfo: [NSLocalizedDescriptionKey: "Could not create the 16 kHz audio converter."])
        }
        conv.downmix = true
        outFormat = out
        converter = conv
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        file = try AVAudioFile(forWriting: url, settings: settings,
                               commonFormat: .pcmFormatFloat32, interleaved: false)
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock(); defer { lock.unlock() }
        guard let file else { return }
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * outFormat.sampleRate / buffer.format.sampleRate) + 64
        guard let out = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: capacity) else { return }
        var supplied = false
        var error: NSError?
        let status = converter.convert(to: out, error: &error) { _, inputStatus in
            if supplied {
                inputStatus.pointee = .noDataNow
                return nil
            }
            supplied = true
            inputStatus.pointee = .haveData
            return buffer
        }
        guard status != .error, out.frameLength > 0 else { return }
        try? file.write(from: out)
        framesWritten += AVAudioFramePosition(out.frameLength)
    }

    /// Finishes the file and returns its length in seconds.
    func close() -> Double {
        lock.lock(); defer { lock.unlock() }
        file = nil                      // AVAudioFile finalizes the WAV header on release
        return Double(framesWritten) / 16_000
    }
}
