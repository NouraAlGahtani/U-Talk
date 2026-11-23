import SwiftUI

// MARK: - Screen 5: session feedback

/// One row in the feedback card. `level` (0...5) must come from real analysis;
/// nil renders an empty state. If `value` is set, it is shown as text instead of bars.
struct FeedbackMetric: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String
    let caption: String
    let level: Int?
    var value: String? = nil

    // MARK: Option A definitions (agreed 2026-11-15)
    //  Fluency      = share of 3-second windows the WavLM model classified as Fluent.
    //  Clarity      = share of script words found (in order) in on-device speech recognition. Script practice only.
    //                 Measures how recognizable the words were, not pronunciation quality.
    //  Pace & pauses = active-speech WPM and pauses (>= 0.35 s), same method as speech_analysis_v3.py.

    static func fluency(_ analysis: SpeechAnalysis) -> FeedbackMetric {
        let total = analysis.windows.count
        let fluent = analysis.count(of: .fluent)
        let share = total > 0 ? Double(fluent) / Double(total) : 0
        return FeedbackMetric(title: "Fluency", symbol: "chart.bar",
                              caption: "\(fluent) of \(total) segments fluent",
                              level: Int((share * 5).rounded()))
    }

    static func clarity(matched: Int, total: Int) -> FeedbackMetric {
        let share = total > 0 ? Double(matched) / Double(total) : 0
        return FeedbackMetric(title: "Clarity", symbol: "mic",
                              caption: "\(matched) of \(total) script words recognized",
                              level: Int((share * 5).rounded()))
    }

    static func pace(wpm: Double?, pauses: PauseAnalysis) -> FeedbackMetric {
        var caption = pauses.pauseCount == 1 ? "1 pause" : "\(pauses.pauseCount) pauses"
        if pauses.longPauseCount > 0 { caption += " (\(pauses.longPauseCount) long)" }
        return FeedbackMetric(title: "Pace & pauses", symbol: "timer", caption: caption, level: nil,
                              value: wpm.map { "\(Int($0.rounded())) wpm" } ?? "—")
    }

    static func unavailable(_ title: String, symbol: String, reason: String) -> FeedbackMetric {
        FeedbackMetric(title: title, symbol: symbol, caption: reason, level: nil)
    }

    /// Shown while the analysis runs.
    static func analyzing(_ kind: PracticeKind) -> [FeedbackMetric] {
        var rows: [FeedbackMetric] = []
        if kind == .script { rows.append(unavailable("Clarity", symbol: "mic", reason: "Analyzing…")) }
        rows.append(unavailable("Fluency", symbol: "chart.bar", reason: "Analyzing…"))
        rows.append(unavailable("Pace & pauses", symbol: "timer", reason: "Analyzing…"))
        return rows
    }

    /// Used only when there is no audio to analyze.
    static let notAnalyzed: [FeedbackMetric] = [
        FeedbackMetric(title: "Fluency", symbol: "chart.bar", caption: "No speech recorded", level: nil),
        FeedbackMetric(title: "Pace & pauses", symbol: "timer", caption: "No speech recorded", level: nil)
    ]
}

/// State of the on-device WavLM analysis shown on the feedback screen.
enum AnalysisState {
    case notRun
    case running
    case done(SpeechAnalysis)
    case failed(String)
}

struct PracticeFeedbackView: View {
    let scenario: PracticeScenario
    let result: PracticeSessionResult
    var day: Int? = nil
    var userName: String? = nil
    var metrics: [FeedbackMetric] = FeedbackMetric.notAnalyzed
    /// Optional custom summary (e.g. generated from real analysis). Defaults to a factual session summary.
    var summary: String? = nil
    var analysis: AnalysisState = .notRun
    let onSave: (_ rating: Int, _ note: String) -> Void

    @State private var rating = 0
    @State private var note = ""
    @FocusState private var noteFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                metricsCard
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                if showsAnalysis {
                    analysisCard
                        .padding(.horizontal, 18)
                        .padding(.top, 14)
                }

                Text("How did this practice feel?")
                    .font(UTalk.serif(20))
                    .foregroundStyle(UTalk.ink)
                    .padding(.horizontal, 18)
                    .padding(.top, 26)

                stars
                    .padding(.horizontal, 18)
                    .padding(.top, 12)

                Text("Add a note (optional)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(UTalk.ink)
                    .padding(.horizontal, 18)
                    .padding(.top, 24)

                TextField("What went well? What was hard?", text: $note, axis: .vertical)
                    .lineLimit(2...5)
                    .font(.system(size: 14))
                    .foregroundStyle(UTalk.ink)
                    .tint(UTalk.forest)
                    .focused($noteFocused)
                    .padding(14)
                    .frame(minHeight: 56, alignment: .topLeading)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(UTalk.track))
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                UTalkPrimaryButton(title: "Save & continue") {
                    noteFocused = false
                    onSave(rating, note.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                .padding(.horizontal, 18)
                .padding(.top, 22)
                .padding(.bottom, 24)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .utalkCyanBlob(size: 300, offset: CGSize(width: -170, height: -40))
        // The header's blue fills the status-bar area too (it used to leave a white strip there).
        .background {
            VStack(spacing: 0) {
                UTalk.periwinkle
                    .frame(height: 0)
                    .ignoresSafeArea(edges: .top)
                Color.white
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: Pieces

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.1)
                    .foregroundStyle(UTalk.ink)
                Text(headline)
                    .font(UTalk.serif(32))
                    .foregroundStyle(UTalk.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(summary ?? defaultSummary)
                    .font(.system(size: 14))
                    .foregroundStyle(UTalk.ink.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            ULogo(size: 72, scalloped: true)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        // extends upwards so pulling the page down never shows white above the header
        .background(UTalk.periwinkle.padding(.top, -600))
    }

    private var metricsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(metrics.enumerated()), id: \.element.id) { i, metric in
                HStack(spacing: 12) {
                    Image(systemName: metric.symbol)
                        .font(.system(size: 14))
                        .foregroundStyle(UTalk.forest)
                        .frame(width: 34, height: 34)
                        .background(UTalk.paleLime, in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.title).font(UTalk.serif(16)).foregroundStyle(UTalk.ink)
                        Text(metric.caption).font(.system(size: 12)).foregroundStyle(UTalk.muted)
                    }
                    Spacer()
                    if let value = metric.value {
                        Text(value)
                            .font(UTalk.serif(18))
                            .foregroundStyle(UTalk.forest)
                    } else {
                        LevelBars(level: metric.level)
                    }
                }
                .padding(.vertical, 14)
                if i < metrics.count - 1 { Divider() }
            }
        }
        .padding(.horizontal, 16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(UTalk.track))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }

    private var showsAnalysis: Bool {
        if case .notRun = analysis { return false }
        return true
    }

    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.badge.magnifyingglass")
                    .foregroundStyle(UTalk.forest)
                Text("Speech analysis")
                    .font(UTalk.serif(16))
                    .foregroundStyle(UTalk.ink)
                Spacer()
                Text("On this device")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(UTalk.forest)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(UTalk.paleLime, in: Capsule())
            }

            switch analysis {
            case .notRun:
                EmptyView()
            case .running:
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Analyzing your recording…")
                        .font(.system(size: 13))
                        .foregroundStyle(UTalk.muted)
                }
            case .failed(let message):
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.orange)
            case .done(let result):
                analysisResult(result)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(UTalk.track))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }

    @ViewBuilder
    private func analysisResult(_ result: SpeechAnalysis) -> some View {
        let total = result.windows.count
        Text(String(format: "%.1f s of speech checked in %d overlapping 3-second segments.", result.audioSeconds, total))
            .font(.system(size: 13))
            .foregroundStyle(UTalk.muted)

        VStack(spacing: 8) {
            ForEach(StutterLabel.allCases) { label in
                let n = result.count(of: label)
                HStack {
                    Text(label.name)
                        .font(.system(size: 14, weight: label == .fluent ? .semibold : .regular))
                        .foregroundStyle(UTalk.ink)
                    Spacer()
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(UTalk.track)
                            Capsule().fill(label == .fluent ? UTalk.mutedGreen : UTalk.periwinkle)
                                .frame(width: total > 0 ? geo.size.width * CGFloat(n) / CGFloat(total) : 0)
                        }
                    }
                    .frame(width: 90, height: 8)
                    Text("\(n)")
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundStyle(UTalk.ink)
                        .frame(width: 24, alignment: .trailing)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(label.name): \(n) of \(total) segments")
            }
        }

        Text("Events detected by the AI model in each segment. This is practice information, not a diagnosis or a fluency score.")
            .font(.system(size: 11))
            .foregroundStyle(UTalk.muted)

        DisclosureGroup("Technical details") {
            VStack(alignment: .leading, spacing: 4) {
                if result.isSimulator {
                    Text("Simulator: timings are from the Mac, not an iPhone.")
                        .foregroundStyle(.orange)
                }
                Text(String(format: "Avg inference: %.1f ms / segment", result.averageInferenceMs))
                Text(String(format: "Preprocessing: %.1f ms", result.preprocessMs))
                if let load = result.modelLoadMs {
                    Text(String(format: "Model load (first use): %.0f ms", load))
                }
                if let mem = result.memoryFootprintMB {
                    Text(String(format: "App memory: %.0f MB", mem))
                }
            }
            .font(.system(size: 12).monospacedDigit())
            .foregroundStyle(UTalk.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
        }
        .font(.system(size: 12, weight: .semibold))
        .tint(UTalk.forest)
    }

    private var stars: some View {
        HStack {
            ForEach(1...5, id: \.self) { value in
                Button {
                    rating = (rating == value) ? 0 : value
                } label: {
                    Image(systemName: value <= rating ? "star.fill" : "star")
                        .font(.system(size: 26))
                        .foregroundStyle(UTalk.forest)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(value) star\(value == 1 ? "" : "s")")
                .accessibilityAddTraits(value == rating ? .isSelected : [])
            }
        }
    }

    // MARK: Text

    private var eyebrow: String {
        let place = scenario.title.uppercased()
        if let day { return "DAY \(day) · \(place)" }
        return place
    }

    private var headline: String {
        if let name = userName, !name.isEmpty { return "Nice work, \(name)" }
        return "Nice work!"
    }

    /// Factual only: what happened in the session, no judgement of speech quality.
    private var defaultSummary: String {
        switch result.kind {
        case .aiConversation:
            let turns = result.turns == 1 ? "1 turn" : "\(result.turns) turns"
            return "You completed \(turns) in \(UTalk.duration(result.duration)). Every conversation counts."
        case .script:
            let takes = result.turns == 1 ? "1 take" : "\(result.turns) takes"
            return "You recorded \(takes) of the script. Listening back is a great way to notice your own progress."
        }
    }
}

#Preview("Not analyzed (current)") {
    PracticeFeedbackView(scenario: .restaurant,
                         result: PracticeSessionResult(kind: .aiConversation, duration: 154, turns: 3,
                                                       plannedTurns: 3, recordingURL: nil, recordingDuration: nil),
                         day: 4, userName: "Sadeem") { _, _ in }
}

#Preview("Layout check – SAMPLE values, not real analysis") {
    PracticeFeedbackView(scenario: .restaurant,
                         result: PracticeSessionResult(kind: .script, duration: 60, turns: 2,
                                                       plannedTurns: 1, recordingURL: nil, recordingDuration: 9),
                         day: 4, userName: "Sadeem",
                         metrics: [
                            FeedbackMetric.clarity(matched: 21, total: 23),
                            FeedbackMetric(title: "Fluency", symbol: "chart.bar", caption: "Sample: 6 of 8 segments fluent", level: 4),
                            FeedbackMetric.pace(wpm: 118, pauses: PauseAnalysis(speechActiveSeconds: 9, pauseCount: 2,
                                                                                longPauseCount: 1, totalPauseSeconds: 1.4))
                         ]) { _, _ in }
}
