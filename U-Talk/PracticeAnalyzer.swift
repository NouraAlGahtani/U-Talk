import Foundation

/// Runs all on-device analysis for a finished session and builds the Option A feedback rows.
/// Nothing here sends audio or text to a server.
enum PracticeAnalyzer {
    struct Report {
        let analysis: AnalysisState
        let metrics: [FeedbackMetric]
    }

    static func run(session: PracticeSessionResult, scenario: PracticeScenario) async -> Report {
        let files = session.audioFiles
        guard !files.isEmpty else {
            return Report(analysis: .failed("No speech audio was recorded in this session."),
                          metrics: FeedbackMetric.notAnalyzed)
        }

        // 1. WavLM stutter-event classification -> stats card + Fluency.
        let analysis: AnalysisState
        let fluency: FeedbackMetric
        do {
            let result = try await StutterClassifier.shared.analyze(fileURLs: files)
            analysis = .done(result)
            fluency = .fluency(result)
        } catch {
            analysis = .failed(error.localizedDescription)
            fluency = .unavailable("Fluency", symbol: "chart.bar", reason: "Not enough speech to analyze")
        }

        // 2. Pauses + speech-active time (v3 method), off the main thread.
        let pauses = await Task.detached(priority: .userInitiated) {
            SpeechMetrics.analyzePauses(files: files)
        }.value

        // 3. Words: script practice transcribes its recording on-device; conversation uses its answers.
        var transcript = session.transcript ?? ""
        var clarity: FeedbackMetric?
        if session.kind == .script, let url = session.recordingURL {
            do {
                transcript = try await SpeechMetrics.transcribeOnDevice(url: url)
                let script = scenario.scriptLines.joined(separator: " ")
                let match = SpeechMetrics.clarity(script: script, recognized: transcript)
                clarity = .clarity(matched: match.matched, total: match.total)
            } catch {
                clarity = .unavailable("Clarity", symbol: "mic", reason: error.localizedDescription)
            }
        }

        let wordCount = SpeechMetrics.words(transcript).count
        let wpm = SpeechMetrics.activeWPM(wordCount: wordCount, pauses: pauses)
        let pace = FeedbackMetric.pace(wpm: wpm, pauses: pauses)

        print(String(format: "[U-TALK AI] Metrics: words %d, speech-active %.2f s, WPM %@, pauses %d (long %d), clarity %@",
                     wordCount, pauses.speechActiveSeconds,
                     wpm.map { String(format: "%.1f", $0) } ?? "n/a",
                     pauses.pauseCount, pauses.longPauseCount,
                     clarity?.caption ?? "n/a"))
        if !transcript.isEmpty { print("[U-TALK AI] Transcript: \(transcript)") }

        var rows: [FeedbackMetric] = []
        if let clarity { rows.append(clarity) }
        rows.append(fluency)
        rows.append(pace)
        return Report(analysis: analysis, metrics: rows)
    }
}
