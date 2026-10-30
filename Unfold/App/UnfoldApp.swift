import SwiftUI

@main
struct UnfoldApp: App {
    @State private var fold = FoldState()
    @State private var progress = ProgressStore()
    @State private var coach = Coach()
    @State private var router = Router()

    init() {
        // `-demoProfile` seeds a lived-in profile for screenshots and stage demos.
        if ProcessInfo.processInfo.arguments.contains("-demoProfile") {
            UserDefaults.standard.set(true, forKey: "seedDemoProfile")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(fold)
                .environment(progress)
                .environment(coach)
                .environment(router)
                .tracksHinge(fold)
                .modifier(WindowSizeReader())
                .preferredColorScheme(.dark)
                .onAppear {
                    if UserDefaults.standard.bool(forKey: "seedDemoProfile") {
                        UserDefaults.standard.removeObject(forKey: "seedDemoProfile")
                        progress.loadDemoProfile()
                    }
                    let arguments = ProcessInfo.processInfo.arguments
                    if arguments.contains("-presenterHinge") {
                        fold.presenterEnabled = true
                    }
                    if let flag = arguments.firstIndex(of: "-presenterAngle"), flag + 1 < arguments.count,
                       let angle = Double(arguments[flag + 1]) {
                        fold.presenterAngle = min(max(angle, 30), 180)
                    }
                }
        }
    }
}

enum AppTab: Hashable {
    case arcade, coach, journey, search
}

/// Lets any screen switch tabs or hand a question to Coach.
@Observable
final class Router {
    var tab: AppTab = .arcade
    var pendingQuestion: String?

    func ask(_ question: String) {
        pendingQuestion = question
        tab = .coach
    }
}
