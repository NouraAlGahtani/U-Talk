import SwiftUI

enum OnboardingRoute: Int, CaseIterable {
    case splash = 0
    case welcome = 1
    case name = 2
    case situations = 3
    case midConversation = 4
    case feedback = 5
    case microphone = 6
    case notifications = 7
    case commitment = 8
    case setupComplete = 9
    case home = 10
}

struct ContentView: View {
    @State private var route: OnboardingRoute = .splash

    @AppStorage("userName") private var userName: String = ""
    @State private var selectedSituations: Set<String> = []
    @State private var selectedHelpers: Set<String> = []
    @State private var selectedFeedback: String = ""
    @AppStorage("selectedScenario") private var selectedScenario: String = ""
    /// Set when onboarding is finished; later launches go straight from the splash to Home.
    @AppStorage("utalk.onboardingComplete") private var onboardingComplete = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            Group {
                switch route {
                case .splash:
                    SplashView {
                        navigate(to: onboardingComplete ? .home : .welcome)
                    }
                case .welcome:
                    WelcomeView {
                        navigate(to: .name)
                    }
                case .name:
                    NameStepView(
                        name: $userName,
                        onBack: { navigate(to: .welcome) },
                        onContinue: { navigate(to: .situations) }
                    )
                case .situations:
                    SituationsStepView(
                        selected: $selectedSituations,
                        onBack: { navigate(to: .name) },
                        onContinue: { navigate(to: .midConversation) }
                    )
                case .midConversation:
                    MidConversationStepView(
                        selected: $selectedHelpers,
                        onBack: { navigate(to: .situations) },
                        onContinue: { navigate(to: .feedback) }
                    )
                case .feedback:
                    FeedbackStepView(
                        selected: $selectedFeedback,
                        onBack: { navigate(to: .midConversation) },
                        onContinue: { navigate(to: .microphone) }
                    )
                case .microphone:
                    MicrophonePermissionView(
                        onBack: { navigate(to: .feedback) },
                        onAllow: {
                            Task {
                                await PracticePermissions.requestMicrophoneAndSpeech()
                                navigate(to: .notifications)
                            }
                        },
                        onSkip: { navigate(to: .notifications) }
                    )
                case .notifications:
                    NotificationsView(
                        onBack: { navigate(to: .microphone) },
                        onContinue: { navigate(to: .commitment) }
                    )
                case .commitment:
                    CommitmentView(
                        onBack: { navigate(to: .notifications) },
                        onContinue: { navigate(to: .setupComplete) }
                    )
                case .setupComplete:
                    SetupCompleteView(
                        onContinue: {
                            OnboardingAnswers.save(situations: selectedSituations,
                                                   helpers: selectedHelpers,
                                                   feedback: selectedFeedback)
                            if let first = selectedSituations.sorted().first {
                                selectedScenario = first
                            }
                            onboardingComplete = true
                            navigate(to: .home)
                        }
                    )
                case .home:
                    MainTabView()
                }
            }
            .id(route)
            .transition(.opacity)
        }
        // "Start over" in Profile → Account clears everything; go back to the welcome screen.
        .onChange(of: onboardingComplete) { _, done in
            guard !done, route == .home else { return }
            // Signed out: start completely fresh, with nothing filled in or picked.
            userName = ""
            selectedSituations = []
            selectedHelpers = []
            selectedFeedback = ""
            selectedScenario = ""
            navigate(to: .welcome)
        }
    }

    private func navigate(to next: OnboardingRoute) {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif

        withAnimation(.easeInOut(duration: 0.35)) {
            route = next
        }
    }
}

#Preview {
    ContentView()
}
