import SwiftUI
import Combine

extension Notification.Name {
    /// Posted when a practice session is finished and saved; MainTabView then shows the Roadmap.
    static let uTalkPracticeFinished = Notification.Name("uTalkPracticeFinished")
}
import Combine

/// Kept so existing screens (ChallengeView, HidesUTalkTabBar) still compile. The bar no longer reads it:
/// it now lives on the Home/Roadmap root pages only (see `uTalkTabBar`).
final class TabBarVisibility: ObservableObject {
    @Published private var hideCount = 0

    var hidden: Bool {
        get { hideCount > 0 }
        set { hideCount = newValue ? hideCount + 1 : max(0, hideCount - 1) }
    }
}

private struct TabBarVisibilityKey: EnvironmentKey {
    static let defaultValue = TabBarVisibility()
}

extension EnvironmentValues {
    var tabBarVisibility: TabBarVisibility {
        get { self[TabBarVisibilityKey.self] }
        set { self[TabBarVisibilityKey.self] = newValue }
    }
}

enum UTalkTab: Hashable {
    case home
    case roadmap
}

struct MainTabView: View {
    @State private var selectedTab: UTalkTab = .home
    @State private var homeStackID = UUID()
    @State private var roadmapStackID = UUID()
    @AppStorage(CelebrationView.pendingKey) private var celebrationPending = false
    @State private var showCelebration = false
    @StateObject private var tabBar = TabBarVisibility()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: UTalkTab.home) {
                NavigationStack {
                    HomeView()
                        .uTalkTabBar($selectedTab)
                }
                .id(homeStackID)
                #if !os(macOS)
                .toolbarVisibility(.hidden, for: .tabBar)
                #endif
            }
            .defaultVisibility(.hidden, for: .tabBar)

            Tab("Roadmap", systemImage: "point.topleft.down.to.point.bottomright.curvepath", value: UTalkTab.roadmap) {
                NavigationStack {
                    RoadmapView()
                        .uTalkTabBar($selectedTab)
                }
                .id(roadmapStackID)
                #if !os(macOS)
                .toolbarVisibility(.hidden, for: .tabBar)
                #endif
            }
            .defaultVisibility(.hidden, for: .tabBar)
        }
        .tabViewStyle(.tabBarOnly)
        .environment(\.tabBarVisibility, tabBar)
        // A finished practice closes all the pages it opened and lands on the Roadmap.
        .onReceive(NotificationCenter.default.publisher(for: .uTalkPracticeFinished)) { _ in
            homeStackID = UUID()
            roadmapStackID = UUID()
            selectedTab = .roadmap
        }
        // Whole roadmap finished: the U pops in with confetti (once).
        .onChange(of: celebrationPending) { _, pending in
            guard pending else { return }
            // let the feedback screen finish closing onto the Roadmap first
            // let the user land on the Roadmap and see the last day ticked first
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.8)) { showCelebration = true }
            }
        }
        .onAppear {
            if celebrationPending { showCelebration = true }
        }
        .overlay {
            if showCelebration {
                CelebrationView {
                    withAnimation(.easeInOut(duration: 0.5)) { showCelebration = false }
                    celebrationPending = false
                }
                .transition(.opacity)
            }
        }
    }
}

extension View {
    /// The custom bottom bar is attached to the first page of each tab (Home, Roadmap) inside its
    /// NavigationStack. Pages opened from there cover it, so they show only their back button,
    /// and nothing has to show/hide the bar while a page is being pushed (that caused a glitch).
    func uTalkTabBar(_ selection: Binding<UTalkTab>) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            UTalkTabBar(selection: selection)
                .frame(maxWidth: .infinity)
                // sits a little lower, into the space above the home indicator
                .padding(.bottom, -10)
                .background {
                    Color.white.ignoresSafeArea(edges: .bottom)
                }
        }
    }
}

struct UTalkTabBar: View {
    @Binding var selection: UTalkTab
    @Namespace private var selectionAnimation

    /// Home and Roadmap each have their own copy of the bar, so the underline can't just slide inside
    /// one bar. Instead, the bar that appears starts the underline where the last bar left it and
    /// slides it to the selected tab.
    private static var lastIndicator: UTalkTab?
    @State private var indicator: UTalkTab?

    var body: some View {
        HStack(spacing: 0) {
            tabButton("Home", icon: "house", tab: .home)
            tabButton("Roadmap", icon: "point.topleft.down.to.point.bottomright.curvepath", tab: .roadmap)
        }
        .onAppear {
            indicator = Self.lastIndicator ?? selection
            Self.lastIndicator = selection
            if indicator != selection {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.25)) { indicator = selection }
                }
            }
        }
        .onChange(of: selection) { _, newValue in
            withAnimation(.easeInOut(duration: 0.25)) { indicator = newValue }
        }
    }

    private func tabButton(_ title: LocalizedStringKey, icon: String, tab: UTalkTab) -> some View {
        let isSelected = selection == tab
        let showsUnderline = (indicator ?? selection) == tab
        let forestGreen = Color(red: 39/255, green: 79/255, blue: 72/255)

        return Button {
            guard selection != tab else { return }
            Self.lastIndicator = selection   // the new tab's bar slides from here
            selection = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .frame(height: 20)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(
                isSelected ? forestGreen : Color(red: 113/255, green: 133/255, blue: 126/255)
            )
            .padding(.top, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .overlay(alignment: .top) {
                GeometryReader { geometry in
                    if showsUnderline {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(forestGreen)
                            .matchedGeometryEffect(id: "selectedTab", in: selectionAnimation)
                            .frame(width: geometry.size.width * 0.70, height: 3)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .frame(height: 3)
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    MainTabView()
}
