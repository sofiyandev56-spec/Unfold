import SwiftUI

struct RootView: View {
    @Environment(Router.self) private var router
    @Environment(FoldState.self) private var fold
    @Environment(Coach.self) private var coach

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            Tab("Arcade", systemImage: "gamecontroller.fill", value: AppTab.arcade) {
                ArcadeView()
            }
            Tab("Coach", systemImage: "sparkles", value: AppTab.coach) {
                CoachView()
            }
            Tab("Journey", systemImage: "trophy.fill", value: AppTab.journey) {
                JourneyView()
            }
            Tab("Search", systemImage: "magnifyingglass", value: AppTab.search, role: .search) {
                SearchView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(Palette.tint)
        .overlay(alignment: .bottom) {
            if fold.presenterEnabled {
                PresenterHingeBar()
                    .padding(.bottom, 70)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.smooth, value: fold.presenterEnabled)
        .task {
            coach.prepare()
            // `-tab coach|journey|search` opens a tab directly, for stage demos.
            let arguments = ProcessInfo.processInfo.arguments
            if let flag = arguments.firstIndex(of: "-tab"), flag + 1 < arguments.count {
                switch arguments[flag + 1] {
                case "coach": router.tab = .coach
                case "journey": router.tab = .journey
                case "search": router.tab = .search
                default: break
                }
            }
        }
    }
}
