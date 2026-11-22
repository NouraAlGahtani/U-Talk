import Foundation

// The 6-day roadmap, built from the onboarding answers.
//
// Onboarding ("Which situations feel hardest?") promises "Your roadmap starts with these", so:
//   • days 1…n are the situations the user picked (up to 3, in the order shown on that screen),
//   • the remaining days are filled from the default order, skipping anything already in the plan.
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
    static let totalDays = PracticeProgress.totalDays

    // MARK: Lessons

    static let introducing = RoadmapLesson(title: "Introducing Yourself",
                                           subtitle: "Greet someone warmly and introduce\nyourself with ease.",
                                           minutes: 5, scenarioID: "about-you")
    static let smallTalk = RoadmapLesson(title: "Small Talk",
                                         subtitle: "Keep a casual chat flowing naturally\nwithout running out of words.",
                                         minutes: 6, scenarioID: "about-you")
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

    /// Used to fill the days after the user's chosen situations (and the whole plan if nothing was chosen).
    static let defaultOrder: [RoadmapLesson] = [
        introducing, restaurant, airport, interview, presenting, phoneCall, appointment
    ]

    // MARK: Plan

    static func lessons(focus: String) -> [RoadmapLesson] {
        let chosen = Set(focus.split(separator: "|").map(String.init))
        var plan: [RoadmapLesson] = []
        var used = Set<String>()

        for item in situations where chosen.contains(item.key) && !used.contains(item.lesson.scenarioID) {
            plan.append(item.lesson)
            used.insert(item.lesson.scenarioID)
        }
        for lesson in defaultOrder where plan.count < totalDays && !used.contains(lesson.scenarioID) {
            plan.append(lesson)
            used.insert(lesson.scenarioID)
        }
        return Array(plan.prefix(totalDays))
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
    }
}
