import Foundation
import CoreML
import AVFoundation

// MARK: - Labels (exact model output order — do not reorder)

enum StutterLabel: Int, CaseIterable, Identifiable {
    case prolongation = 0, repetition, block, interjection, fluent

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .prolongation: "Prolongation"
        case .repetition: "Repetition"
        case .block: "Block"
        case .interjection: "Interjection"
        case .fluent: "Fluent"
        }
    }
}

// MARK: - Results

struct WindowPrediction: Identifiable {
    let id: Int                  // window index
    let startSeconds: Double
    let label: StutterLabel      // argmax of logits
    let probabilities: [Float]   // softmax(logits), same order as StutterLabel
    let inferenceMs: Double
}

struct SpeechAnalysis {
    let windows: [WindowPrediction]
    let audioSeconds: Double
    /// Non-nil only when this call had to load the model.
    let modelLoadMs: Double?
    let preprocessMs: Double
    let memoryFootprintMB: Double?
    let isSimulator: Bool

    func count(of label: StutterLabel) -> Int { windows.filter { $0.label == label }.count }
    var totalInferenceMs: Double { windows.reduce(0) { $0 + $1.inferenceMs } }
    var averageInferenceMs: Double { windows.isEmpty ? 0 : totalInferenceMs / Double(windows.count) }
}

struct ModelBenchmark {
    let modelLoadMs: Double?
    let warmupRuns: Int
    let timedRuns: Int
    let averageMs: Double
    let medianMs: Double
    let fastestMs: Double
    let slowestMs: Double
    let memoryFootprintMB: Double?
    let isSimulator: Bool
    /// Seconds of audio per window divided by average inference time (same definition as benchmark_coreml.py).
    var realTimeFactor: Double { averageMs > 0 ? 3000 / averageMs : 0 }
}

enum ClassifierError: LocalizedError {
    case modelMissing
    case badOutput(String)
    case audio(String)
    case tooShort(Double)

    var errorDescription: String? {
        switch self {
        case .modelMissing:
            "U_TALK_WavLM model not found in the app bundle. Add U_TALK_WavLM.mlpackage to the Yusr target."
        case .badOutput(let detail):
            "Unexpected model output: \(detail)"
        case .audio(let detail):
            "Audio could not be prepared: \(detail)"
        case .tooShort(let seconds):
            String(format: "Recording is %.1f s. At least 1 s of audio is needed for analysis.", seconds)
        }
    }
}

// MARK: - Classifier

/// On-device inference for U_TALK_WavLM.mlpackage.
/// Preprocessing and windowing mirror backend/validate_coreml_uclass.py:
///   mono mixdown -> 16 kHz -> Float32 (no normalization)
///   windows of 48,000 samples, hop 16,000; stop when < 16,000 samples remain; zero-pad the last window.
/// Runs as an actor so inference never blocks the main thread.
actor StutterClassifier {
    static let shared = StutterClassifier()

    static let sampleRate: Double = 16_000
    static let windowSize = 48_000
    static let hopSize = 16_000
    static let inputName = "audio"          // from convert_to_coreml.py
    static let resourceName = "U_TALK_WavLM"

    private var model: MLModel?
    private var outputName: String?

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    // MARK: Loading

    /// Loads the compiled model once. Returns load time in ms if it loaded now, nil if already loaded.
    @discardableResult
    func loadIfNeeded() throws -> Double? {
        if model != nil { return nil }
        guard let url = Bundle.main.url(forResource: Self.resourceName, withExtension: "mlmodelc") else {
            throw ClassifierError.modelMissing
        }
        let config = MLModelConfiguration()
        config.computeUnits = .all            // same as the Mac benchmark
        let start = CFAbsoluteTimeGetCurrent()
        let loaded = try MLModel(contentsOf: url, configuration: config)
        let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000

        let outputs = loaded.modelDescription.outputDescriptionsByName.keys.sorted()
        guard let first = outputs.first else { throw ClassifierError.badOutput("model has no outputs") }
        guard loaded.modelDescription.inputDescriptionsByName[Self.inputName] != nil else {
            let names = loaded.modelDescription.inputDescriptionsByName.keys.joined(separator: ", ")
            throw ClassifierError.badOutput("expected input '\(Self.inputName)', model has: \(names)")
        }
        model = loaded
        outputName = first
        print("[U-TALK AI] Model loaded in \(String(format: "%.0f", ms)) ms. Input: \(Self.inputName). Outputs: \(outputs)")
        return ms
    }

    // MARK: Analysis of a recorded file

    func analyze(fileURL: URL) throws -> SpeechAnalysis {
        try analyze(fileURLs: [fileURL])
    }

    /// Analyzes each file separately (e.g. one per conversation answer) and combines the windows.
    /// Windows never span two files. Files shorter than 1 s contribute no windows.
    func analyze(fileURLs: [URL]) throws -> SpeechAnalysis {
        let loadMs = try loadIfNeeded()

        var windows: [WindowPrediction] = []
        var prepMs = 0.0
        var seconds = 0.0
        for url in fileURLs {
            let prepStart = CFAbsoluteTimeGetCurrent()
            let samples = try Self.loadMono16k(url: url)
            prepMs += (CFAbsoluteTimeGetCurrent() - prepStart) * 1000
            let offset = seconds
            seconds += Double(samples.count) / Self.sampleRate

            var start = 0
            while start < samples.count {
                let remaining = samples.count - start
                if remaining < Self.hopSize { break }          // same rule as the Python validation
                let length = min(Self.windowSize, remaining)
                let (logits, ms) = try predict(samples, from: start, count: length)
                let probs = Self.softmax(logits)
                let best = probs.indices.max(by: { probs[$0] < probs[$1] }) ?? StutterLabel.fluent.rawValue
                windows.append(WindowPrediction(id: windows.count,
                                                startSeconds: offset + Double(start) / Self.sampleRate,
                                                label: StutterLabel(rawValue: best) ?? .fluent,
                                                probabilities: probs,
                                                inferenceMs: ms))
                start += Self.hopSize
            }
        }
        guard !windows.isEmpty else { throw ClassifierError.tooShort(seconds) }

        let result = SpeechAnalysis(windows: windows,
                                    audioSeconds: seconds,
                                    modelLoadMs: loadMs,
                                    preprocessMs: prepMs,
                                    memoryFootprintMB: Self.memoryFootprintMB(),
                                    isSimulator: Self.isSimulator)
        Self.log(result)
        return result
    }

    // MARK: Benchmark (mirrors benchmark_coreml.py: 5 warm-up, 30 timed, random-normal input)

    func benchmark(warmup: Int = 5, runs: Int = 30) throws -> ModelBenchmark {
        let loadMs = try loadIfNeeded()
        var rng = SeededGenerator(seed: 42)
        var input = [Float](repeating: 0, count: Self.windowSize)
        for i in 0..<input.count { input[i] = Self.normal(&rng) }

        for _ in 0..<warmup { _ = try predict(input, from: 0, count: input.count) }
        var times: [Double] = []
        for _ in 0..<runs { times.append(try predict(input, from: 0, count: input.count).ms) }
        times.sort()

        let result = ModelBenchmark(modelLoadMs: loadMs,
                                    warmupRuns: warmup,
                                    timedRuns: runs,
                                    averageMs: times.reduce(0, +) / Double(times.count),
                                    medianMs: times.count % 2 == 1 ? times[times.count / 2]
                                        : (times[times.count / 2 - 1] + times[times.count / 2]) / 2,
                                    fastestMs: times.first ?? 0,
                                    slowestMs: times.last ?? 0,
                                    memoryFootprintMB: Self.memoryFootprintMB(),
                                    isSimulator: Self.isSimulator)
        print(String(format: "[U-TALK AI] Benchmark%@: avg %.1f ms, median %.1f, min %.1f, max %.1f, RTF %.1fx, memory %@ MB",
                     result.isSimulator ? " (SIMULATOR — runs on the Mac, not iPhone)" : "",
                     result.averageMs, result.medianMs, result.fastestMs, result.slowestMs, result.realTimeFactor,
                     result.memoryFootprintMB.map { String(format: "%.0f", $0) } ?? "?"))
        return result
    }

    // MARK: Core prediction

    private func predict(_ samples: [Float], from start: Int, count: Int) throws -> (logits: [Float], ms: Double) {
        guard let model, let outputName else { throw ClassifierError.modelMissing }

        let input = try MLMultiArray(shape: [1, NSNumber(value: Self.windowSize)], dataType: .float32)
        input.withUnsafeMutableBufferPointer(ofType: Float.self) { buffer, _ in
            buffer.update(repeating: 0)                                 // zero-padding
            samples.withUnsafeBufferPointer { src in
                for i in 0..<count { buffer[i] = src[start + i] }
            }
        }

        let features = try MLDictionaryFeatureProvider(dictionary: [Self.inputName: MLFeatureValue(multiArray: input)])
        let t0 = CFAbsoluteTimeGetCurrent()
        let output = try model.prediction(from: features)
        let ms = (CFAbsoluteTimeGetCurrent() - t0) * 1000

        guard let logits = output.featureValue(for: outputName)?.multiArrayValue else {
            throw ClassifierError.badOutput("output '\(outputName)' is not a multi-array")
        }
        guard logits.count == StutterLabel.allCases.count else {
            throw ClassifierError.badOutput("expected 5 values, got \(logits.count) (shape \(logits.shape))")
        }
        let values = (0..<logits.count).map { logits[$0].floatValue }
        return (values, ms)
    }

    // MARK: Audio preprocessing

    /// Reads any audio file and returns mono Float32 samples at 16 kHz, without normalization.
    static func loadMono16k(url: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)        // processingFormat is Float32, deinterleaved
        let inFormat = file.processingFormat
        let frames = AVAudioFrameCount(file.length)
        guard frames > 0, let inBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: frames) else {
            throw ClassifierError.audio("empty file")
        }
        try file.read(into: inBuffer)
        guard let channels = inBuffer.floatChannelData else { throw ClassifierError.audio("no float data") }

        let n = Int(inBuffer.frameLength)
        let channelCount = Int(inFormat.channelCount)
        var mono = [Float](repeating: 0, count: n)
        for c in 0..<channelCount {
            let ch = channels[c]
            for i in 0..<n { mono[i] += ch[i] }
        }
        if channelCount > 1 {
            let scale = 1 / Float(channelCount)
            for i in 0..<n { mono[i] *= scale }
        }

        if inFormat.sampleRate == sampleRate { return mono }   // script recordings are already 16 kHz
        return try resample(mono, from: inFormat.sampleRate)
    }

    /// Note: AVAudioConverter's resampler is not bit-identical to scipy.resample_poly.
    /// Not used for the app's own recordings, which are captured at 16 kHz.
    private static func resample(_ mono: [Float], from rate: Double) throws -> [Float] {
        guard let srcFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: rate, channels: 1, interleaved: false),
              let dstFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false),
              let converter = AVAudioConverter(from: srcFormat, to: dstFormat),
              let src = AVAudioPCMBuffer(pcmFormat: srcFormat, frameCapacity: AVAudioFrameCount(mono.count)) else {
            throw ClassifierError.audio("could not create resampler")
        }
        converter.sampleRateConverterQuality = AVAudioQuality.max.rawValue
        src.frameLength = AVAudioFrameCount(mono.count)
        mono.withUnsafeBufferPointer { p in
            src.floatChannelData![0].update(from: p.baseAddress!, count: mono.count)
        }
        let capacity = AVAudioFrameCount(Double(mono.count) * sampleRate / rate) + 4096
        guard let dst = AVAudioPCMBuffer(pcmFormat: dstFormat, frameCapacity: capacity) else {
            throw ClassifierError.audio("could not allocate output buffer")
        }
        var supplied = false
        var conversionError: NSError?
        let status = converter.convert(to: dst, error: &conversionError) { _, inputStatus in
            if supplied {
                inputStatus.pointee = .endOfStream
                return nil
            }
            supplied = true
            inputStatus.pointee = .haveData
            return src
        }
        if status == .error {
            throw ClassifierError.audio(conversionError?.localizedDescription ?? "conversion failed")
        }
        return Array(UnsafeBufferPointer(start: dst.floatChannelData![0], count: Int(dst.frameLength)))
    }

    // MARK: Helpers

    static func softmax(_ logits: [Float]) -> [Float] {
        let maxLogit = logits.max() ?? 0
        let exps = logits.map { Foundation.exp($0 - maxLogit) }
        let sum = exps.reduce(0, +)
        return exps.map { $0 / sum }
    }

    /// App memory footprint (same number Xcode's memory gauge shows).
    static func memoryFootprintMB() -> Double? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return nil }
        return Double(info.phys_footprint) / 1_048_576
    }

    private static func normal(_ rng: inout SeededGenerator) -> Float {
        let u1 = Double.random(in: Double.ulpOfOne..<1, using: &rng)
        let u2 = Double.random(in: 0..<1, using: &rng)
        return Float((-2 * Foundation.log(u1)).squareRoot() * cos(2 * .pi * u2))
    }

    private static func log(_ a: SpeechAnalysis) {
        var line = String(format: "[U-TALK AI] %@Analyzed %.2f s → %d windows. ",
                          a.isSimulator ? "(SIMULATOR) " : "", a.audioSeconds, a.windows.count)
        line += StutterLabel.allCases.map { "\($0.name): \(a.count(of: $0))" }.joined(separator: ", ")
        line += String(format: ". Preprocess %.1f ms, avg inference %.1f ms/window", a.preprocessMs, a.averageInferenceMs)
        if let load = a.modelLoadMs { line += String(format: ", model load %.0f ms", load) }
        if let mem = a.memoryFootprintMB { line += String(format: ", memory %.0f MB", mem) }
        print(line)
        for w in a.windows {
            let probs = w.probabilities.map { String(format: "%.3f", $0) }.joined(separator: " ")
            print(String(format: "[U-TALK AI]   window %d @ %.0f s: %@ [%@] %.1f ms",
                         w.id, w.startSeconds, w.label.name, probs, w.inferenceMs))
        }
    }
}

/// Deterministic RNG (SplitMix64) for a reproducible benchmark input.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
