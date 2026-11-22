import SwiftUI

// Connects the lesson flow (Home / Roadmap → PracticeSelectionView) to the practice screens.
// Kept in its own file so the onboarding/home screens only change in two NavigationLinks.

extension PracticeScenario {
    /// Maps a lesson title from HomeView / RoadmapView to a practice scenario.
    /// Returns nil for lessons that don't have a scenario yet.
    static func forLesson(_ title: String) -> PracticeScenario? {
        switch title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "introducing yourself", "first hello", "small talk", "daily conversation":
            return .aboutYou
        case "at the restaurant", "coffee order":
            return .restaurant
        case "job interview":
            return .interview
        case "presenting an idea":
            return .presentation
        case "book an appointment":
            return .appointment
        case "at the airport":
            return .airport
        case "phone call", "phone calls":
            return .phoneCall
        default:
            return nil
        }
    }
}

/// Destination of the "AI Conversation" / "Script Practice" cards in PracticeSelectionView.
struct LessonPracticeDestination: View {
    let kind: PracticeKind
    let day: Int
    let lessonTitle: String

    var body: some View {
        if let scenario = PracticeScenario.forLesson(lessonTitle) {
            ScenarioIntroView(scenario: scenario, kind: kind, day: day)
                .modifier(HidesUTalkTabBar())
        } else {
            LessonComingSoonView(kind: kind, day: day, lessonTitle: lessonTitle)
        }
    }
}

/// Hides the custom bottom bar from MainTabView while a practice screen is open (same approach as ChallengeView).
struct HidesUTalkTabBar: ViewModifier {
    @Environment(\.tabBarVisibility) private var tabBar

    func body(content: Content) -> some View {
        content
            .onAppear { tabBar.hidden = true }
            .onDisappear { tabBar.hidden = false }
    }
}

/// Shown for lessons that don't have a practice scenario yet.
private struct LessonComingSoonView: View {
    let kind: PracticeKind
    let day: Int
    let lessonTitle: String

    var body: some View {
        VStack(spacing: 14) {
            ULogo(size: 90)
            Text(lessonTitle)
                .font(UTalk.serif(28))
                .foregroundStyle(UTalk.forest)
            Text("Day \(day) · \(kind == .aiConversation ? "AI Conversation" : "Script Practice")")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(UTalk.muted)
            Text("This practice is coming soon.")
                .font(.system(size: 15))
                .foregroundStyle(UTalk.ink)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea())
    }
}
