import SwiftUI
import Combine

/// Lets a pushed screen hide the custom bottom bar. The bar is a safeAreaInset
/// on the TabView, so `.toolbar(.hidden, for: .tabBar)` has no effect on it.
final class TabBarVisibility: ObservableObject {
    @Published var hidden = false
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
    case profile
}

struct MainTabView: View {
    @State private var selectedTab: UTalkTab = .home
    @StateObject private var tabBar = TabBarVisibility()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: UTalkTab.home) {
                NavigationStack {
                    HomeView()
                }
                #if !os(macOS)
                .toolbarVisibility(.hidden, for: .tabBar)
                #endif
            }
            .defaultVisibility(.hidden, for: .tabBar)

            Tab("Roadmap", systemImage: "point.topleft.down.to.point.bottomright.curvepath", value: UTalkTab.roadmap) {
                NavigationStack {
                    RoadmapView()
                }
                #if !os(macOS)
                .toolbarVisibility(.hidden, for: .tabBar)
                #endif
            }
            .defaultVisibility(.hidden, for: .tabBar)

            Tab("Profile", systemImage: "person", value: UTalkTab.profile) {
                NavigationStack {
                    ProfileMenuView()
                }
                #if !os(macOS)
                .toolbarVisibility(.hidden, for: .tabBar)
                #endif
            }
            .defaultVisibility(.hidden, for: .tabBar)
        }
        .tabViewStyle(.tabBarOnly)
        .environment(\.tabBarVisibility, tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !tabBar.hidden {
                UTalkTabBar(selection: $selectedTab)
                    .frame(maxWidth: .infinity)
                    // sits a little lower, into the space above the home indicator
                    .padding(.bottom, -10)
                    .background {
                        Color.white.ignoresSafeArea(edges: .bottom)
                    }
            }
        }
    }
}

struct UTalkTabBar: View {
    @Binding var selection: UTalkTab
    @Namespace private var selectionAnimation

    var body: some View {
        HStack(spacing: 0) {
            tabButton("Home", icon: "house", tab: .home)
            tabButton("Roadmap", icon: "point.topleft.down.to.point.bottomright.curvepath", tab: .roadmap)
            tabButton("Profile", icon: "person", tab: .profile)
        }
        .animation(.easeInOut(duration: 0.25), value: selection)
    }

    private func tabButton(_ title: LocalizedStringKey, icon: String, tab: UTalkTab) -> some View {
        let isSelected = selection == tab
        let forestGreen = Color(red: 39/255, green: 79/255, blue: 72/255)

        return Button {
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
                    if isSelected {
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
