import Foundation
import Speech

// MARK: - Pause analysis (Swift port of analyze_pauses in backend/speech_analysis_v3.py)

struct PauseAnalysis {
    var speechActiveSeconds: Double = 0
    var pauseCount = 0
    var longPauseCount = 0
    var totalPauseSeconds: Double = 0

    static func + (a: PauseAnalysis, b: PauseAnalysis) -> PauseAnalysis {
        PauseAnalysis(speechActiveSeconds: a.speechActiveSeconds + b.speechActiveSeconds,
                      pauseCount: a.pauseCount + b.pauseCount,
                      longPauseCount: a.longPauseCount + b.longPauseCount,
                      totalPauseSeconds: a.totalPauseSeconds + b.totalPauseSeconds)
    }
}

enum SpeechMetrics {
    static let sampleRate = 16_000
    static let frameSeconds = 0.02           // 20 ms frames
    static let minPauseSeconds = 0.35
    static let longPauseSeconds = 0.7

    /// Same parameters as speech_analysis_v3.py:
    /// noise floor = 20th percentile of frame RMS, threshold = max(0.008, floor * 2.5),
    /// merge gaps <= 7 frames (140 ms), drop speech runs < 6 frames (120 ms),
    /// internal pauses >= 0.35 s, long pauses >= 0.7 s. Leading/trailing silence is not a pause.
    static func analyzePauses(_ audio: [Float]) -> PauseAnalysis {
        let frameSize = Int(Double(sampleRate) * frameSeconds)   // 320 samples
        let frameCount = audio.count / frameSize
        guard frameCount > 0 else { return PauseAnalysis() }

        var rms = [Float](repeating: 0, count: frameCount)
        audio.withUnsafeBufferPointer { p in
            for f in 0..<frameCount {
                var sum: Float = 0
                let base = f * frameSize
                for i in 0..<frameSize { let v = p[base + i]; sum += v * v }
                rms[f] = (sum / Float(frameSize)).squareRoot()
            }
        }

        let noiseFloor = percentile(rms, 20)
        let threshold = max(Float(0.008), noiseFloor * 2.5)
        var mask = rms.map { $0 > threshold }

        // Merge gaps of 140 ms or less.
        var runs = speechRuns(mask)
        if runs.count > 1 {
            for i in 0..<(runs.count - 1) where runs[i + 1].start - runs[i].end <= 7 {
                for f in runs[i].end..<runs[i + 1].start { mask[f] = true }
            }
        }
        // Remove speech detections shorter than 120 ms.
        for run in speechRuns(mask) where run.end - run.start < 6 {
            for f in run.start..<run.end { mask[f] = false }
        }

        runs = speechRuns(mask)
        guard !runs.isEmpty else { return PauseAnalysis() }

        var result = PauseAnalysis()
        result.speechActiveSeconds = Double(mask.filter { $0 }.count) * frameSeconds
        if runs.count > 1 {
            for i in 0..<(runs.count - 1) {
                let pause = Double(runs[i + 1].start - runs[i].end) * frameSeconds
                if pause >= minPauseSeconds {
                    result.pauseCount += 1
                    result.totalPauseSeconds += pause
                    if pause >= longPauseSeconds { result.longPauseCount += 1 }
                }
            }
        }
        return result
    }

    /// Runs of `true` as half-open frame ranges (same as get_runs in Python).
    private static func speechRuns(_ mask: [Bool]) -> [(start: Int, end: Int)] {
        var runs: [(Int, Int)] = []
        var start: Int?
        for (i, on) in mask.enumerated() {
            if on, start == nil { start = i }
            if !on, let s = start { runs.append((s, i)); start = nil }
        }
        if let s = start { runs.append((s, mask.count)) }
        return runs.map { (start: $0.0, end: $0.1) }
    }

    /// numpy.percentile default (linear interpolation).
    static func percentile(_ values: [Float], _ p: Double) -> Float {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let rank = p / 100 * Double(sorted.count - 1)
        let lo = Int(rank.rounded(.down)), hi = Int(rank.rounded(.up))
        let frac = Float(rank - Double(lo))
        return sorted[lo] + (sorted[hi] - sorted[lo]) * frac
    }

    /// Pause analysis per file, summed (gaps between conversation turns are not counted as pauses).
    static func analyzePauses(files: [URL]) -> PauseAnalysis {
        files.reduce(PauseAnalysis()) { total, url in
            guard let samples = try? StutterClassifier.loadMono16k(url: url) else { return total }
            return total + analyzePauses(samples)
        }
    }

    // MARK: Words

    /// Same tokenization idea as analyze_text in v3: lowercase word tokens, apostrophes kept.
    static func words(_ text: String) -> [String] {
        let normalized = text.lowercased().replacingOccurrences(of: "’", with: "'")
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "'"))
        return normalized.components(separatedBy: allowed.inverted)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "'")) }
            .filter { !$0.isEmpty }
    }

    /// Active-speech words per minute (v3: total_words / speech_active_seconds * 60).
    static func activeWPM(wordCount: Int, pauses: PauseAnalysis) -> Double? {
        guard wordCount > 0, pauses.speechActiveSeconds >= 1 else { return nil }
        return Double(wordCount) / pauses.speechActiveSeconds * 60
    }

    // MARK: Clarity (script practice)

    /// How many script words appear, in order, in what on-device speech recognition heard.
    /// Uses the longest common subsequence, so extra or repeated words are not penalized.
    static func clarity(script: String, recognized: String) -> (matched: Int, total: Int) {
        let a = expandContractions(words(script)), b = expandContractions(words(recognized))
        guard !a.isEmpty else { return (0, 0) }
        guard !b.isEmpty else { return (0, a.count) }
        var prev = [Int](repeating: 0, count: b.count + 1)
        var curr = prev
        for i in 1...a.count {
            for j in 1...b.count {
                curr[j] = a[i - 1] == b[j - 1] ? prev[j - 1] + 1 : max(prev[j], curr[j - 1])
            }
            swap(&prev, &curr)
        }
        return (prev[b.count], a.count)
    }

    /// So "I am" in a script matches "I'm" from speech recognition (and the other way round).
    /// Used only for Clarity; word counts for WPM keep the v3 tokenization.
    static func expandContractions(_ tokens: [String]) -> [String] {
        let map: [String: [String]] = [
            "i'm": ["i", "am"], "i'd": ["i", "would"], "i'll": ["i", "will"], "i've": ["i", "have"],
            "you're": ["you", "are"], "we're": ["we", "are"], "they're": ["they", "are"],
            "it's": ["it", "is"], "that's": ["that", "is"], "there's": ["there", "is"],
            "what's": ["what", "is"], "here's": ["here", "is"], "let's": ["let", "us"],
            "don't": ["do", "not"], "doesn't": ["does", "not"], "didn't": ["did", "not"],
            "can't": ["can", "not"], "cannot": ["can", "not"], "won't": ["will", "not"],
            "isn't": ["is", "not"], "aren't": ["are", "not"], "wasn't": ["was", "not"],
            "couldn't": ["could", "not"], "wouldn't": ["would", "not"], "shouldn't": ["should", "not"]
        ]
        return tokens.flatMap { map[$0] ?? [$0] }
    }

    // MARK: On-device transcription of a recorded file

    enum TranscriptionError: LocalizedError {
        case notAuthorized, unavailable, onDeviceUnsupported
        var errorDescription: String? {
            switch self {
            case .notAuthorized: "Speech recognition permission is off."
            case .unavailable: "Speech recognition is unavailable right now."
            case .onDeviceUnsupported: "On-device speech recognition isn't supported on this device."
            }
        }
    }

    /// Transcribes on the device only (audio is never sent to a server). Returns "" if no speech was recognized.
    static func transcribeOnDevice(url: URL) async throws -> String {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard status == .authorized else { throw TranscriptionError.notAuthorized }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")), recognizer.isAvailable else {
            throw TranscriptionError.unavailable
        }
        guard recognizer.supportsOnDeviceRecognition else { throw TranscriptionError.onDeviceUnsupported }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        request.taskHint = .dictation

        return try await withCheckedThrowingContinuation { continuation in
            var finished = false
            _ = recognizer.recognitionTask(with: request) { result, error in
                _ = recognizer   // keep the recognizer alive until the task ends
                guard !finished else { return }
                if let error {
                    finished = true
                    let ns = error as NSError
                    if ns.domain == "kAFAssistantErrorDomain" && ns.code == 1110 {
                        continuation.resume(returning: "")    // no speech recognized
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else if let result, result.isFinal {
                    finished = true
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
}
