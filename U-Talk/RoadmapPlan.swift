import Foundation

// The 6-day roadmap, built from the onboarding answers.
//
// 7-day roadmap:
//   • Day 1 is always "Introducing Yourself" (you introduce yourself before ordering food or interviewing),
//   • next, the situations picked in onboarding ("Which situations feel hardest?"): top priority,
//   • then every other situation, so all six are covered by Day 7.
//   Within the picked group and within the rest, lessons go from easier to harder (their level).
// RoadmapView and HomeView both read the plan from here, so the map and Home always show the same lesson.

struct RoadmapLesson: Hashable {
    /// Also passed to PracticeSelectionView; PracticeScenario.forLesson(_:) maps it to a scenario.
    let title: String
    let subtitle: String
    let minutes: Int
    /// Scenario id, used to avoid two days with the same practice.
    let scenarioID: String

    var duration: String { "\(minutes) min" }
}

enum RoadmapPlan {
    /// "|"-separated situation keys saved at the end of onboarding.
    static let focusKey = "roadmapFocus"
    /// Introducing Yourself + the six onboarding situations.
    static let maxDays = 7

    // MARK: Lessons

    static let introducing = RoadmapLesson(title: "Introducing Yourself",
                                           subtitle: "Greet someone warmly and introduce\nyourself with ease.",
                                           minutes: 5, scenarioID: "about-you")
    static let smallTalk = RoadmapLesson(title: "Small Talk",
                                         subtitle: "Keep a casual chat flowing naturally\nwithout running out of words.",
                                         minutes: 6, scenarioID: "small-talk")
    static let restaurant = RoadmapLesson(title: "At the Restaurant",
                                          subtitle: "Order a meal, ask a question and\nget the bill.",
                                          minutes: 6, scenarioID: "restaurant")
    static let airport = RoadmapLesson(title: "At the Airport",
                                       subtitle: "Check in for a flight and ask\nabout your gate.",
                                       minutes: 6, scenarioID: "airport")
    static let interview = RoadmapLesson(title: "Job Interview",
                                         subtitle: "Introduce yourself and talk about\nyour strengths.",
                                         minutes: 6, scenarioID: "interview")
    static let presenting = RoadmapLesson(title: "Presenting an Idea",
                                          subtitle: "Speak clearly and confidently in\nfront of an audience.",
                                          minutes: 6, scenarioID: "presentation")
    static let phoneCall = RoadmapLesson(title: "Phone Call",
                                         subtitle: "Call for help and explain what\nyou need with confidence.",
                                         minutes: 5, scenarioID: "phone-call")
    static let appointment = RoadmapLesson(title: "Book an Appointment",
                                           subtitle: "Find a time that works and confirm\nthe details.",
                                           minutes: 5, scenarioID: "appointment")

    /// Onboarding situation (as SituationsStepView saves it) → lesson, in the order shown on that screen.
    static let situations: [(key: String, lesson: RoadmapLesson)] = [
        ("Ordering at a restaurant", restaurant),
        ("Travel and booking", airport),
        ("Small talk", smallTalk),
        ("Job interview", interview),
        ("Presentations", presenting),
        ("Phone calls", phoneCall)
    ]

    /// Every lesson from easiest to hardest. A lesson's position here is its level.
    /// Face-to-face and predictable first; phone calls (no visual cues) and high-stakes speaking last.
    static let levelOrder: [RoadmapLesson] = [
        introducing,   // 1 talk about yourself
        smallTalk,     // 2 casual chat
        restaurant,    // 3 short, predictable exchange
        airport,       // 4 give details, answer questions
        appointment,   // 5 booking, dates and times
        phoneCall,     // 6 no face, no visual cues
        interview,     // 7 high stakes
        presenting     // 8 speaking to an audience
    ]

    static func level(of lesson: RoadmapLesson) -> Int {
        levelOrder.firstIndex(of: lesson) ?? levelOrder.count
    }

    // MARK: Plan

    static func lessons(focus: String) -> [RoadmapLesson] {
        let chosenKeys = Set(focus.split(separator: "|").map(String.init))
        let chosen = situations.filter { chosenKeys.contains($0.key) }.map(\.lesson)

        let byLevel: (RoadmapLesson, RoadmapLesson) -> Bool = { level(of: $0) < level(of: $1) }
        let picked = chosen.sorted(by: byLevel)
        let others = situations.map(\.lesson).filter { !chosen.contains($0) }.sorted(by: byLevel)
        return [introducing] + picked + others
    }

    /// Number of days in the roadmap for the saved onboarding answers.
    static var currentDayCount: Int {
        lessons(focus: UserDefaults.standard.string(forKey: focusKey) ?? "").count
    }

    /// Lesson for a day (1-based). Days past the end repeat the last lesson.
    static func lesson(day: Int, focus: String) -> RoadmapLesson {
        let plan = lessons(focus: focus)
        return plan[min(max(day, 1), plan.count) - 1]
    }
}

// MARK: - Saving the onboarding answers

enum OnboardingAnswers {
    /// Called when onboarding finishes. Builds the roadmap from the chosen situations and
    /// carries the other answers into the matching Profile → Settings switches.
    static func save(situations: Set<String>, helpers: Set<String>, feedback: String) {
        let defaults = UserDefaults.standard

        let ordered = RoadmapPlan.situations.map(\.key).filter { situations.contains($0) }
        defaults.set(ordered.joined(separator: "|"), forKey: RoadmapPlan.focusKey)

        // A new roadmap starts at day 1.
        defaults.set(0, forKey: PracticeProgress.completedDaysKey)
        defaults.set(1, forKey: PracticeProgress.currentDayKey)

        // "What helps you mid-conversation?" → Settings (ProfileView)
        defaults.set(helpers.contains("Hints when I get stuck"), forKey: "utalk.hintsEnabled")
        defaults.set(helpers.contains("Suggested responses"), forKey: "utalk.suggestedResponses")
        defaults.set(helpers.contains("More time to think"), forKey: "utalk.extraThinkingTime")

        // "How should feedback sound?" → Settings uses "Encouraging" / "Suggestions" / "Both"
        switch feedback {
        case "Encouraging": defaults.set("Encouraging", forKey: "utalk.feedbackStyle")
        case "Suggestions to Improve": defaults.set("Suggestions", forKey: "utalk.feedbackStyle")
        case "Both": defaults.set("Both", forKey: "utalk.feedbackStyle")
        default: break
        }

        // Reminders were scheduled on the notifications step; update their text for the new roadmap.
        Task { await PracticeReminders.reschedule() }
    }
}
