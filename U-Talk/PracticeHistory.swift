import Foundation

// Practice history + roadmap progress. Everything is stored on this device only.
//
//  • Session list:    UserDefaults "uTalkSavedSessions" ([UTalkSession]) — the key AllSessionsView already reads.
//  • Session details: Application Support/UTalk/session_details.json — the conversation / script,
//                     the feedback metrics, the model's segment counts, rating and note.
//  • Roadmap:         UserDefaults "completedRoadmapDays" (RoadmapView) and "currentPracticeDay"
//                     (HomeView, ProfileView) are updated together, so both screens agree.
//
// No audio is kept in the history: recordings stay temporary, only text and numbers are saved.

// MARK: - Saved details

struct SavedLine: Codable, Hashable {
    /// "assistant", "user" or "script"
    let role: String
    let text: String
}

struct SavedMetric: Codable, Hashable {
    let title: String
    let symbol: String
    let caption: String
    let level: Int?
    let value: String?

    init(_ metric: FeedbackMetric) {
        title = metric.title
        symbol = metric.symbol
        caption = metric.caption
        level = metric.level
        value = metric.value
    }
}

struct SessionDetails: Codable, Identifiable {
    let id: UUID
    let scenarioID: String
    let scenarioTitle: String
    let aiRoleLabel: String
    let isConversation: Bool
    let day: Int?
    let turns: Int
    let lines: [SavedLine]
    var metrics: [SavedMetric] = []
    /// Model segment counts by label name (e.g. "Repetition": 2). nil until the analysis finishes.
    var segmentCounts: [String: Int]? = nil
    /// Why there are no metrics, if the analysis failed.
    var analysisMessage: String? = nil
    var rating: Int? = nil
    var note: String? = nil
}

// MARK: - History store

enum SessionHistory {
    static let summaryKey = "uTalkSavedSessions"

    /// Saves a finished session. Returns its id, used to add the analysis and rating later.
    @discardableResult
    static func saveFinished(_ result: PracticeSessionResult, scenario: PracticeScenario, day: Int?) -> UUID {
        let id = UUID()
        let isConversation = result.kind == .aiConversation

        let lines: [SavedLine] = isConversation
            ? result.conversation.map { SavedLine(role: $0.role, text: $0.content) }
            : scenario.scriptLines.map { SavedLine(role: "script", text: $0) }

        // 1. Row for AllSessionsView
        var sessions = loadSummaries()
        sessions.append(UTalkSession(id: id,
                                     title: scenario.title,
                                     mode: isConversation ? .conversation : .script,
                                     date: Date(),
                                     durationSeconds: max(1, Int(result.duration.rounded())),
                                     status: .completed))
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: summaryKey)
        }

        // 2. Details
        var all = loadAllDetails()
        all[id] = SessionDetails(id: id,
                                 scenarioID: scenario.id,
                                 scenarioTitle: scenario.title,
                                 aiRoleLabel: scenario.aiRoleLabel,
                                 isConversation: isConversation,
                                 day: day,
                                 turns: result.turns,
                                 lines: lines)
        writeAllDetails(all)
        return id
    }

    static func saveAnalysis(id: UUID, metrics: [FeedbackMetric], analysis: AnalysisState) {
        update(id) { details in
            details.metrics = metrics.map { SavedMetric($0) }
            switch analysis {
            case .done(let result):
                var counts: [String: Int] = [:]
                for label in StutterLabel.allCases { counts[label.name] = result.count(of: label) }
                details.segmentCounts = counts
                details.analysisMessage = nil
            case .failed(let message):
                details.analysisMessage = message
            case .notRun, .running:
                break
            }
        }
    }

    static func saveRating(id: UUID, rating: Int, note: String) {
        update(id) { details in
            details.rating = rating > 0 ? rating : nil
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            details.note = trimmed.isEmpty ? nil : trimmed
        }
    }

    static func details(for id: UUID) -> SessionDetails? {
        loadAllDetails()[id]
    }

    /// Deletes one session (row + details). Roadmap progress is not affected.
    static func delete(id: UUID) {
        let remaining = loadSummaries().filter { $0.id != id }
        if let data = try? JSONEncoder().encode(remaining) {
            UserDefaults.standard.set(data, forKey: summaryKey)
        }
        var all = loadAllDetails()
        all[id] = nil
        writeAllDetails(all)
    }

    /// Deletes every saved session. Roadmap progress is not affected.
    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: summaryKey)
        if let url = detailsURL { try? FileManager.default.removeItem(at: url) }
    }

    // MARK: Storage

    private static func loadSummaries() -> [UTalkSession] {
        guard let data = UserDefaults.standard.data(forKey: summaryKey) else { return [] }
        return (try? JSONDecoder().decode([UTalkSession].self, from: data)) ?? []
    }

    private static func update(_ id: UUID, _ change: (inout SessionDetails) -> Void) {
        var all = loadAllDetails()
        guard var details = all[id] else { return }
        change(&details)
        all[id] = details
        writeAllDetails(all)
    }

    private static var detailsURL: URL? {
        guard let base = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                      appropriateFor: nil, create: true) else { return nil }
        let folder = base.appendingPathComponent("UTalk", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("session_details.json")
    }

    private static func loadAllDetails() -> [UUID: SessionDetails] {
        guard let url = detailsURL,
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([SessionDetails].self, from: data) else { return [:] }
        return Dictionary(list.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
    }

    private static func writeAllDetails(_ all: [UUID: SessionDetails]) {
        guard let url = detailsURL,
              let data = try? JSONEncoder().encode(Array(all.values)) else { return }
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            print("[U-TALK history] Could not save session details: \(error)")
        }
    }
}

// MARK: - Roadmap progress

enum PracticeProgress {
    static let completedDaysKey = "completedRoadmapDays"   // RoadmapView
    static let currentDayKey = "currentPracticeDay"        // HomeView, ProfileView
    /// Days in this user's roadmap (2–6, depends on what they picked in onboarding).
    static var totalDays: Int { RoadmapPlan.currentDayCount }

    /// A session counts as completing the day when the user answered every planned step
    /// (3 answers in an AI conversation) or recorded at least one script take.
    static func countsAsComplete(_ result: PracticeSessionResult, scenario: PracticeScenario) -> Bool {
        switch result.kind {
        case .aiConversation: return result.turns >= max(1, scenario.plannedTurns)
        case .script: return result.recordingURL != nil
        }
    }

    /// Marks `day` as done and unlocks the next one. Only the current day can unlock the next;
    /// repeating an earlier day changes nothing.
    static func complete(day: Int) {
        let defaults = UserDefaults.standard
        let completed = defaults.integer(forKey: completedDaysKey)
        guard day == completed + 1, day <= totalDays else { return }
        defaults.set(day, forKey: completedDaysKey)
        defaults.set(min(day + 1, totalDays), forKey: currentDayKey)
        if day == totalDays {
            defaults.set(true, forKey: CelebrationView.pendingKey)   // MainTabView shows the celebration
        }
        Task { await PracticeReminders.reschedule() }   // reminder text names the next lesson
    }
}
