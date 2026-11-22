import SwiftUI
import UIKit

// MARK: - Screen 1 & 3: scenario intro (AI conversation / script practice)

struct ScenarioIntroView: View {
    let scenario: PracticeScenario
    let kind: PracticeKind
    /// Shown in the DAY badge. Pass nil until the roadmap/progress system provides it.
    var day: Int? = nil
    /// User's first name for the feedback headline, if the app has it.
    var userName: String? = UserProfile.storedName

    @Environment(\.dismiss) private var dismiss
    @State private var showSession = false
    @State private var completed = false

    private var heroColor: Color { kind == .aiConversation ? UTalk.periwinkle : UTalk.paleLime }
    private var stepTint: Color { kind == .aiConversation ? UTalk.periwinkle.opacity(0.6) : UTalk.paleLime }
    private var summary: String { kind == .aiConversation ? scenario.aiSummary : scenario.scriptSummary }
    private var steps: [String] { kind == .aiConversation ? scenario.aiSteps : scenario.scriptSteps }
    private var goals: [String] { kind == .aiConversation ? scenario.aiGoals : scenario.scriptGoals }

    var body: some View {
        VStack(spacing: 0) {
            hero

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TagPill(text: kind.tag)
                        .padding(.bottom, 10)
                    Text(scenario.title)
                        .font(UTalk.serif(32))
                        .foregroundStyle(UTalk.ink)
                    Text(summary)
                        .font(.system(size: 14))
                        .foregroundStyle(UTalk.muted)
                        .padding(.top, 6)

                    SectionLabel(text: "You will practice")
                        .padding(.top, 22)
                        .padding(.bottom, 10)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                            NumberedRow(index: i + 1, text: step, tint: stepTint)
                        }
                    }

                    SectionLabel(text: "Learning goals")
                        .padding(.top, 22)
                        .padding(.bottom, 10)
                    UTalkFlowLayout(spacing: 8) {
                        ForEach(goals, id: \.self) { GoalChip(text: $0) }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            UTalkPrimaryButton(title: "Start practice") { showSession = true }
                .padding(.horizontal, 22)
                .padding(.bottom, 12)
        }
        .utalkCyanBlob()
        .background(Color.white.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.layoutDirection, .leftToRight)
        .fullScreenCover(isPresented: $showSession, onDismiss: {
            if completed { dismiss() }
        }) {
            PracticeSessionContainer(scenario: scenario, kind: kind, day: day, userName: userName) { didComplete in
                completed = didComplete
                showSession = false
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .top) {
            ScenarioIllustration(scenario: scenario)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

            HStack(alignment: .top) {
                UTalkBackButton { dismiss() }
                Spacer()
                if let day { DayBadge(day: day) }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .frame(height: 220)
        .background(heroColor.ignoresSafeArea(edges: .top))
    }
}

/// Uses the illustration from Assets.xcassets if present, otherwise an SF Symbol placeholder.
struct ScenarioIllustration: View {
    let scenario: PracticeScenario
    var body: some View {
        if UIImage(named: scenario.illustrationAsset) != nil {
            Image(scenario.illustrationAsset)
                .resizable()
                .scaledToFit()
                .padding(.top, 40)
                .accessibilityHidden(true)
        } else {
            Image(systemName: scenario.symbol)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(UTalk.forest)
                .padding(.bottom, 36)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Session flow: practice screen -> feedback screen

struct PracticeSessionContainer: View {
    let scenario: PracticeScenario
    let kind: PracticeKind
    var day: Int?
    var userName: String?
    /// true = user saved feedback (flow complete), false = user left early.
    let onClose: (Bool) -> Void

    @State private var result: PracticeSessionResult?
    @State private var analysis: AnalysisState = .notRun
    @State private var metrics: [FeedbackMetric] = FeedbackMetric.notAnalyzed
    /// Id of this session in practice history (nil if it wasn't saved).
    @State private var historyID: UUID?

    /// The scenario with the user's name filled in (only "Talk About Yourself" uses it today).
    private var activeScenario: PracticeScenario { scenario.personalized(name: userName) }

    var body: some View {
        Group {
            if let result {
                PracticeFeedbackView(scenario: activeScenario, result: result, day: day, userName: userName,
                                     metrics: metrics, analysis: analysis) { rating, note in
                    if let historyID { SessionHistory.saveRating(id: historyID, rating: rating, note: note) }
                    onClose(true)
                }
            } else {
                switch kind {
                case .aiConversation:
                    AIConversationPracticeView(scenario: activeScenario,
                                               onFinish: { finish($0) },
                                               onExit: { onClose(false) })
                case .script:
                    ScriptPracticeView(scenario: activeScenario,
                                       onFinish: { finish($0) },
                                       onExit: { onClose(false) })
                }
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    /// Shows feedback immediately, then fills it in from on-device analysis
    /// (WavLM stats + Fluency, Clarity for scripts, Pace & pauses).
    private func finish(_ session: PracticeSessionResult) {
        analysis = .running
        metrics = FeedbackMetric.analyzing(session.kind)
        withAnimation { result = session }

        // Save to history and unlock the next roadmap day (only sessions where the user actually spoke).
        let spoke = session.kind == .aiConversation ? session.turns > 0 : session.recordingURL != nil
        if spoke {
            historyID = SessionHistory.saveFinished(session, scenario: activeScenario, day: day)
        }
        if let day, PracticeProgress.countsAsComplete(session, scenario: activeScenario) {
            PracticeProgress.complete(day: day)
        }

        Task { @MainActor in
            let report = await PracticeAnalyzer.run(session: session, scenario: activeScenario)
            withAnimation {
                analysis = report.analysis
                metrics = report.metrics
            }
            if let historyID {
                SessionHistory.saveAnalysis(id: historyID, metrics: report.metrics, analysis: report.analysis)
            }
        }
    }
}

// MARK: - Temporary entry point for testing my screens (until the team wires navigation)

struct PracticeScenarioPickerView: View {
    @AppStorage(UserProfile.nameKey) private var testName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach([ScenarioCategory.personal, .rolePlay, .everyday], id: \.self) { category in
                    Section(category.rawValue) {
                        ForEach(PracticeScenario.all.filter { $0.category == category }) { scenario in
                            NavigationLink {
                                ScenarioIntroView(scenario: scenario, kind: .aiConversation)
                            } label: {
                                Label(scenario.title, systemImage: scenario.symbol)
                            }
                            NavigationLink {
                                ScenarioIntroView(scenario: scenario, kind: .script)
                            } label: {
                                Text("Script practice")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 36)
                            }
                        }
                    }
                }
                Section {
                    TextField("Your name (for testing)", text: $testName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                } header: {
                    Text("Your name")
                } footer: {
                    Text("Temporary: the onboarding screens will set this. Used by Talk About Yourself and the feedback screen.")
                }
                Section("Developer") {
                    NavigationLink("AI model check (on-device benchmark)") {
                        ModelCheckView()
                    }
                }
            }
            .navigationTitle("My scenarios")
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

#Preview("Picker") { PracticeScenarioPickerView() }

#Preview("AI intro – Restaurant") {
    NavigationStack { ScenarioIntroView(scenario: .restaurant, kind: .aiConversation, day: 4) }
}

#Preview("Script intro – Interview") {
    NavigationStack { ScenarioIntroView(scenario: .interview, kind: .script, day: 4) }
}
