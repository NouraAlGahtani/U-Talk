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

/// Profile button at the top right of Home and Roadmap. One shared view so both are identical
/// (same size, shadow and position); place it as the last item of the header HStack, top-aligned.
struct ProfileAvatarLink: View {
    let initial: String
    private let forest = Color(red: 39/255, green: 79/255, blue: 72/255)

    var body: some View {
        NavigationLink {
            ProfileMenuView()
        } label: {
            Text(initial)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundStyle(forest)
                .frame(width: 48, height: 48)
                .background(.white, in: Circle())
                .shadow(color: .black.opacity(0.10), radius: 9, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Profile")
    }
}

/// No longer needed: pushed pages never show the bar now (it lives on the Home/Roadmap root pages).
/// Kept as a no-op so the existing `.modifier(HidesUTalkTabBar())` calls still compile.
struct HidesUTalkTabBar: ViewModifier {
    func body(content: Content) -> some View { content }
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
