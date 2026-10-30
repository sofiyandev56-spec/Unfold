import Foundation

struct SprintQuestion: Identifiable {
    let id = UUID()
    let concept: String
    let prompt: String
    let code: String
    let options: [String]
    let answer: Int
    let explanation: String
    var codeOptions = false
}

struct RaceTile: Identifiable {
    let id = UUID()
    let code: String
    let typeName: String
    let isSendable: Bool
    let why: String
}

struct FlipCard: Identifiable {
    let id: String
    let task: String
    let answer: String
    let detail: String
    let snippet: String
    let symbol: String
}

struct TimelineEvent: Identifiable {
    let id = UUID()
    let year: Int
    let title: String
    let detail: String
    let symbol: String
}

/// A searchable piece of knowledge, shared by Search and Coach's offline notes.
struct Note: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let world: World
}

enum Curriculum {
    // MARK: Swift Sprint

    static let sprint: [SprintQuestion] = [
        SprintQuestion(concept: "Value semantics", prompt: "What prints?",
                       code: "let numbers = [3, 1, 2]\nlet sorted = numbers.sorted()\nprint(numbers)",
                       options: ["[1, 2, 3]", "[3, 1, 2]", "Compile error"], answer: 1,
                       explanation: "sorted() returns a new array. numbers is a let constant and is never changed.", codeOptions: true),
        SprintQuestion(concept: "Copy-on-write", prompt: "What prints?",
                       code: "var a = [1, 2, 3]\nvar b = a\nb.append(4)\nprint(a.count)",
                       options: ["3", "4", "Compile error"], answer: 0,
                       explanation: "Arrays are value types. b is an independent copy, so appending to b leaves a with 3 items.", codeOptions: true),
        SprintQuestion(concept: "Reference types", prompt: "What prints?",
                       code: "class Box { var value = 0 }\nlet a = Box()\nlet b = a\nb.value = 42\nprint(a.value)",
                       options: ["0", "42", "Compile error"], answer: 1,
                       explanation: "Classes are reference types: a and b point to the same Box. let fixes the reference, not the object.", codeOptions: true),
        SprintQuestion(concept: "Optionals", prompt: "What prints?",
                       code: "let name: String? = nil\nprint(name ?? \"Guest\")",
                       options: ["nil", "Guest", "Optional(\"Guest\")"], answer: 1,
                       explanation: "?? is the nil-coalescing operator: it unwraps the optional or falls back to the default.", codeOptions: true),
        SprintQuestion(concept: "Constants", prompt: "Will it compile?",
                       code: "let score = 10\nscore += 5",
                       options: ["Yes, score is 15", "No, score is a let constant"], answer: 1,
                       explanation: "A let constant can't be mutated. Declare it with var to change it."),
        SprintQuestion(concept: "Struct mutability", prompt: "Will it compile?",
                       code: "struct Point { var x = 0 }\nlet p = Point()\np.x = 5",
                       options: ["Yes", "No, p is a let constant"], answer: 1,
                       explanation: "A struct held in a let is immutable as a whole, even if its properties are declared with var."),
        SprintQuestion(concept: "Functions", prompt: "What prints?",
                       code: "func greet(_ name: String, loud: Bool = false) -> String {\n    loud ? name.uppercased() : name\n}\nprint(greet(\"swift\", loud: true))",
                       options: ["swift", "SWIFT", "Swift"], answer: 1,
                       explanation: "A single-expression function returns implicitly; loud: true picks uppercased().", codeOptions: true),
        SprintQuestion(concept: "Higher-order functions", prompt: "What prints?",
                       code: "let values = [1, 2, 3, 4]\nlet result = values\n    .filter { $0.isMultiple(of: 2) }\n    .map { $0 * 10 }\nprint(result)",
                       options: ["[10, 30]", "[20, 40]", "[2, 4]"], answer: 1,
                       explanation: "filter keeps 2 and 4, then map multiplies each by 10.", codeOptions: true),
        SprintQuestion(concept: "Exhaustive switch", prompt: "Will it compile?",
                       code: "enum Device { case phone, duo, watch }\nlet d = Device.duo\nswitch d {\ncase .phone: print(\"Phone\")\ncase .duo: print(\"Duo\")\n}",
                       options: ["Yes, prints Duo", "No, the switch isn't exhaustive"], answer: 1,
                       explanation: "Switches over enums must handle every case. .watch is missing, so add it or a default."),
        SprintQuestion(concept: "Closures capture", prompt: "What prints?",
                       code: "var count = 0\nlet increment = { count += 1 }\nincrement()\nincrement()\nprint(count)",
                       options: ["0", "1", "2"], answer: 2,
                       explanation: "Closures capture variables, not copies of their values, so both calls change the same count.", codeOptions: true),
        SprintQuestion(concept: "Lazy properties", prompt: "Which keyword delays work until first use?",
                       code: "class Course {\n    ___ var lessons = loadLessons()\n}",
                       options: ["lazy", "static", "weak", "final"], answer: 0,
                       explanation: "A lazy property's initial value isn't computed until the first time it's read.", codeOptions: true),
        SprintQuestion(concept: "Retain cycles", prompt: "Which capture breaks the retain cycle?",
                       code: "class Player {\n    var onScore: (() -> Void)?\n    func setup() {\n        onScore = { [___ self] in\n            self?.celebrate()\n        }\n    }\n}",
                       options: ["weak", "strong", "inout", "static"], answer: 0,
                       explanation: "[weak self] stops the closure owning the Player. self becomes optional, hence self?.", codeOptions: true),
        SprintQuestion(concept: "reduce", prompt: "What prints?",
                       code: "let total = (1...5).reduce(0, +)\nprint(total)",
                       options: ["5", "15", "120"], answer: 1,
                       explanation: "reduce starts at 0 and adds each number: 1 + 2 + 3 + 4 + 5 = 15.", codeOptions: true),
        SprintQuestion(concept: "async/await", prompt: "Will it compile?",
                       code: "func fetchScore() async -> Int { 42 }\n\nfunc show() {\n    let s = await fetchScore()\n}",
                       options: ["Yes", "No, show() isn't async"], answer: 1,
                       explanation: "await can only be used in an async context. Mark show() async or start a Task."),
        SprintQuestion(concept: "Observation", prompt: "What does @Observable do here?",
                       code: "@Observable\nclass GameModel {\n    var score = 0\n}",
                       options: ["Updates SwiftUI views when score changes", "Saves score to disk", "Makes the class thread-safe"], answer: 0,
                       explanation: "The Observation macro tracks which properties a view reads and refreshes only those views."),
        SprintQuestion(concept: "SwiftUI state", prompt: "Which property wrapper fits?",
                       code: "struct ScoreView: View {\n    ___ private var score = 0\n    var body: some View {\n        Button(\"\\(score)\") { score += 1 }\n    }\n}",
                       options: ["@State", "@Binding", "@Environment", "static"], answer: 0,
                       explanation: "@State gives a view its own source of truth that survives redraws.", codeOptions: true),
        SprintQuestion(concept: "Strings", prompt: "What prints?",
                       code: "let words = [\"swift\", \"ui\", \"kit\"]\nprint(words.joined(separator: \"-\"))",
                       options: ["swiftuikit", "swift-ui-kit", "[swift, ui, kit]"], answer: 1,
                       explanation: "joined(separator:) concatenates the elements, putting the separator between them.", codeOptions: true),
        SprintQuestion(concept: "Dictionaries", prompt: "What prints?",
                       code: "var scores = [\"Ana\": 90]\nscores[\"Ben\", default: 0] += 5\nprint(scores[\"Ben\"]!)",
                       options: ["5", "95", "nil"], answer: 0,
                       explanation: "The default subscript treats a missing key as 0, then adds 5 and stores it.", codeOptions: true),
        SprintQuestion(concept: "Protocol extensions", prompt: "What prints?",
                       code: "protocol Foldable { func fold() -> String }\nextension Foldable {\n    func fold() -> String { \"Folded\" }\n}\nstruct Duo: Foldable {}\nprint(Duo().fold())",
                       options: ["Folded", "Compile error", "Duo"], answer: 0,
                       explanation: "A protocol extension can supply a default implementation, so Duo conforms for free.", codeOptions: true),
        SprintQuestion(concept: "Failable initializers", prompt: "What prints?",
                       code: "let number = Int(\"42a\")\nprint(number == nil)",
                       options: ["true", "false", "Crash"], answer: 0,
                       explanation: "Int(String) returns nil when the text isn't a valid number. It never crashes.", codeOptions: true),
        SprintQuestion(concept: "guard", prompt: "Will it compile?",
                       code: "func play(user: String?) {\n    guard let user else {\n        print(\"No user\")\n    }\n    print(user)\n}",
                       options: ["Yes", "No, guard's else must exit"], answer: 1,
                       explanation: "A guard's else block must leave the scope, with return, throw, break or continue."),
        SprintQuestion(concept: "Actors", prompt: "From outside the actor, calling deposit needs…",
                       code: "actor Bank {\n    var balance = 0\n    func deposit(_ x: Int) {\n        balance += x\n    }\n}",
                       options: ["await", "try", "Nothing extra", "DispatchQueue.main"], answer: 0,
                       explanation: "Actor-isolated methods are asynchronous from outside: callers await while the actor runs one task at a time."),
        SprintQuestion(concept: "Tuples", prompt: "What prints?",
                       code: "let launch = (name: \"Swift\", year: 2014)\nprint(launch.1)",
                       options: ["Swift", "2014", "year"], answer: 1,
                       explanation: "Tuple elements can be read by label or by position. Position 1 is the year.", codeOptions: true),
    ]

    // MARK: Data Race

    static let raceTiles: [RaceTile] = [
        RaceTile(code: "struct Score {\n    let points: Int\n}", typeName: "Score", isSendable: true,
                 why: "A struct whose stored properties are all Sendable is implicitly Sendable. Each side gets its own copy."),
        RaceTile(code: "let level = 7", typeName: "Int", isSendable: true,
                 why: "Int is a value type and Sendable. Copies can't be shared mutable state."),
        RaceTile(code: "class Cache {\n    var items: [String] = []\n}", typeName: "Cache", isSendable: false,
                 why: "A class with mutable state is shared by reference. Two actors writing items at once is a data race."),
        RaceTile(code: "final class Config: Sendable {\n    let name: String\n}", typeName: "Config", isSendable: true,
                 why: "A final class whose stored properties are immutable and Sendable can conform to Sendable."),
        RaceTile(code: "struct Player {\n    var name: String\n    var friends: [String]\n}", typeName: "Player", isSendable: true,
                 why: "var inside a struct is fine: sending a struct sends a copy, so nothing is shared."),
        RaceTile(code: "enum Mode {\n    case solo, duo\n}", typeName: "Mode", isSendable: true,
                 why: "Enums without associated values, or with Sendable ones, are implicitly Sendable."),
        RaceTile(code: "class Counter {\n    var value = 0\n}", typeName: "Counter", isSendable: false,
                 why: "A mutable class instance isn't Sendable. Wrap the state in an actor instead."),
        RaceTile(code: "struct Session {\n    let cache: Cache  // a class\n}", typeName: "Session", isSendable: false,
                 why: "A struct is only Sendable if everything it stores is. This one holds a non-Sendable class reference."),
        RaceTile(code: "let names: [String] = [\"Ada\"]", typeName: "[String]", isSendable: true,
                 why: "Arrays of Sendable elements are Sendable value types."),
        RaceTile(code: "@MainActor\nclass ViewModel {\n    var title = \"\"\n}", typeName: "ViewModel", isSendable: true,
                 why: "Global-actor-isolated classes are implicitly Sendable. Others can hold the reference but must await to touch it."),
        RaceTile(code: "actor Leaderboard {\n    var top: [Int] = []\n}", typeName: "Leaderboard", isSendable: true,
                 why: "Actors are always Sendable. They protect their own state by running one task at a time."),
        RaceTile(code: "let action: () -> Void = {\n    count += 1\n}", typeName: "() -> Void", isSendable: false,
                 why: "A plain closure may capture mutable state. Only @Sendable closures can cross isolation boundaries."),
        RaceTile(code: "let action: @Sendable () -> Void = {\n    print(\"Hello\")\n}", typeName: "@Sendable () -> Void", isSendable: true,
                 why: "@Sendable closures promise to capture only Sendable values, so they can run anywhere."),
        RaceTile(code: "final class Logger {\n    let id: UUID\n}", typeName: "Logger", isSendable: false,
                 why: "Classes never get implicit Sendable, even final and immutable ones. You must write : Sendable."),
        RaceTile(code: "let launched = Date()", typeName: "Date", isSendable: true,
                 why: "Date is a Foundation value type and is Sendable."),
        RaceTile(code: "class Node {\n    var next: Node?\n}", typeName: "Node", isSendable: false,
                 why: "A mutable linked list shared by reference isn't safe to touch from two actors."),
        RaceTile(code: "struct Point: Sendable {\n    var x, y: Double\n}", typeName: "Point", isSendable: true,
                 why: "An explicit Sendable conformance on a struct of Doubles. The compiler checks it."),
        RaceTile(code: "enum Outcome {\n    case won(Int)\n    case lost(String)\n}", typeName: "Outcome", isSendable: true,
                 why: "Associated values are Int and String, both Sendable, so the enum is too."),
    ]

    // MARK: Fold & Flip

    static let cards: [FlipCard] = [
        FlipCard(id: "foundationmodels", task: "Run a private, on-device language model", answer: "FoundationModels",
                 detail: "LanguageModelSession talks to the model behind Apple Intelligence, entirely on device.",
                 snippet: "let session =\n    LanguageModelSession()\nlet reply = try await\n    session.respond(to: q)", symbol: "sparkles"),
        FlipCard(id: "observation", task: "Refresh SwiftUI views when a model property changes", answer: "Observation",
                 detail: "The @Observable macro tracks exactly which properties each view reads.",
                 snippet: "@Observable class Game {\n    var score = 0\n}", symbol: "eye"),
        FlipCard(id: "swiftdata", task: "Persist model objects with Swift-native code", answer: "SwiftData",
                 detail: "@Model turns a class into a persistent model; ModelContainer stores it.",
                 snippet: "@Model class Lesson {\n    var title: String\n}", symbol: "cylinder.split.1x2"),
        FlipCard(id: "widgetkit", task: "Put glanceable info on the Home Screen", answer: "WidgetKit",
                 detail: "Widgets render SwiftUI views from a timeline the system schedules.",
                 snippet: "struct StreakWidget: Widget { … }", symbol: "square.grid.2x2"),
        FlipCard(id: "activitykit", task: "Show a live score in the Dynamic Island", answer: "ActivityKit",
                 detail: "Live Activities update the Lock Screen and Dynamic Island in real time.",
                 snippet: "try Activity.request(\n    attributes: attrs,\n    content: content)", symbol: "capsule"),
        FlipCard(id: "vision", task: "Find text or faces in a photo", answer: "Vision",
                 detail: "Vision runs on-device computer-vision requests like text recognition.",
                 snippet: "let request =\n    RecognizeTextRequest()", symbol: "text.viewfinder"),
        FlipCard(id: "metal", task: "Program the GPU for graphics and compute", answer: "Metal",
                 detail: "Metal is Apple's low-overhead API for GPU rendering and parallel compute.",
                 snippet: "let device =\n    MTLCreateSystemDefaultDevice()", symbol: "cpu"),
        FlipCard(id: "arkit", task: "Anchor content to the real world through the camera", answer: "ARKit",
                 detail: "ARKit tracks the device and the world; RealityKit renders the scene.",
                 snippet: "let config =\n    ARWorldTrackingConfiguration()", symbol: "arkit"),
        FlipCard(id: "corehaptics", task: "Play custom, precisely timed haptic patterns", answer: "Core Haptics",
                 detail: "CHHapticEngine plays transient and continuous haptic events you design.",
                 snippet: "let engine =\n    try CHHapticEngine()", symbol: "waveform"),
        FlipCard(id: "appintents", task: "Expose app actions to Siri, Spotlight and Shortcuts", answer: "App Intents",
                 detail: "Describe actions in Swift once and the system surfaces them everywhere.",
                 snippet: "struct StartGame: AppIntent { … }", symbol: "wand.and.stars"),
        FlipCard(id: "cloudkit", task: "Sync someone's data across their devices through iCloud", answer: "CloudKit",
                 detail: "CloudKit stores records in iCloud containers, private or public.",
                 snippet: "let db = CKContainer.default()\n    .privateCloudDatabase", symbol: "icloud"),
        FlipCard(id: "corelocation", task: "Find where the device is", answer: "Core Location",
                 detail: "Location updates, geofencing and headings, with the person's permission.",
                 snippet: "for try await update in\n    CLLocationUpdate.liveUpdates() {\n    …\n}", symbol: "location"),
        FlipCard(id: "healthkit", task: "Read steps and workouts with permission", answer: "HealthKit",
                 detail: "A secure, permissioned store for health and fitness data.",
                 snippet: "let store = HKHealthStore()", symbol: "heart"),
        FlipCard(id: "siwa", task: "Offer a privacy-first sign-in", answer: "Sign in with Apple",
                 detail: "AuthenticationServices provides the button and the credential flow.",
                 snippet: "SignInWithAppleButton(\n    .signIn,\n    onRequest: { _ in },\n    onCompletion: { _ in }\n)", symbol: "person.badge.key"),
        FlipCard(id: "keychain", task: "Store a password or token securely", answer: "Keychain Services",
                 detail: "The Security framework's keychain encrypts small secrets at rest.",
                 snippet: "SecItemAdd(\n    query as CFDictionary,\n    nil\n)", symbol: "key"),
        FlipCard(id: "storekit", task: "Sell in-app subscriptions", answer: "StoreKit",
                 detail: "Product and Transaction give a Swift-native purchase flow.",
                 snippet: "let products = try await\n    Product.products(for: ids)", symbol: "creditcard"),
        FlipCard(id: "glass", task: "Give a custom control the Liquid Glass material", answer: "glassEffect(_:in:)",
                 detail: "SwiftUI's modifier for Liquid Glass. Combine shapes in a GlassEffectContainer.",
                 snippet: "Button(\"Play\") { }\n    .glassEffect()", symbol: "drop"),
        FlipCard(id: "hinge", task: "React to iPhone Duo's hinge angle", answer: "onHingeChange",
                 detail: "New in iOS 27.1: DeviceHinge reports the angle and whether it's closed, partly open or open.",
                 snippet: ".onHingeChange { old, new in\n    angle = new.hinge?.angle\n}", symbol: "book.pages"),
        FlipCard(id: "arrangement", task: "Lay out two views that rearrange when the device folds", answer: "ArrangementView",
                 detail: "New in iOS 27.1: split and overlay styles that respect the fold's reserved region.",
                 snippet: "ArrangementView {\n    Lessons()\n} secondary: {\n    Detail()\n}", symbol: "rectangle.split.2x1"),
        FlipCard(id: "notifications", task: "Schedule a local reminder", answer: "UserNotifications",
                 detail: "UNUserNotificationCenter schedules alerts with time or location triggers.",
                 snippet: "try await center.add(request)", symbol: "bell"),
    ]

    // MARK: Time Hinge

    static let timeline: [TimelineEvent] = [
        TimelineEvent(year: 1976, title: "Apple is founded", detail: "Steve Jobs, Steve Wozniak and Ronald Wayne start Apple on April 1; the Apple I follows.", symbol: "building.2"),
        TimelineEvent(year: 1984, title: "Macintosh says hello", detail: "The Mac brings the graphical interface and the mouse to everyone.", symbol: "desktopcomputer"),
        TimelineEvent(year: 1997, title: "Steve Jobs returns", detail: "Apple completes its purchase of NeXT, whose software becomes the foundation of Mac OS X and iOS.", symbol: "arrow.uturn.backward"),
        TimelineEvent(year: 1998, title: "The iMac arrives", detail: "A translucent all-in-one that made computers friendly again.", symbol: "display"),
        TimelineEvent(year: 2001, title: "iPod: 1,000 songs in your pocket", detail: "Apple's first big step beyond the Mac.", symbol: "ipod"),
        TimelineEvent(year: 2003, title: "The iTunes Music Store opens", detail: "Legal music downloads at 99 cents a song.", symbol: "music.note"),
        TimelineEvent(year: 2006, title: "The first Intel Macs", detail: "The Mac moves from PowerPC to Intel processors.", symbol: "memorychip"),
        TimelineEvent(year: 2007, title: "iPhone is introduced", detail: "An iPod, a phone and an internet communicator in one device.", symbol: "iphone"),
        TimelineEvent(year: 2008, title: "The App Store opens", detail: "Third-party native apps arrive with 500 titles on day one.", symbol: "app.badge"),
        TimelineEvent(year: 2010, title: "iPad launches", detail: "A new category between phone and laptop.", symbol: "ipad"),
        TimelineEvent(year: 2011, title: "Siri debuts on iPhone 4S", detail: "An intelligent assistant you talk to.", symbol: "waveform"),
        TimelineEvent(year: 2014, title: "Swift is announced", detail: "Unveiled at WWDC on June 2 as a fast, safe successor to Objective-C.", symbol: "swift"),
        TimelineEvent(year: 2015, title: "Apple Watch goes on sale", detail: "Apple's most personal device reaches wrists in April.", symbol: "applewatch"),
        TimelineEvent(year: 2016, title: "AirPods ship", detail: "Wireless earbuds with a case that pairs in one tap.", symbol: "airpods"),
        TimelineEvent(year: 2019, title: "SwiftUI is introduced", detail: "A declarative way to build interfaces across every Apple platform.", symbol: "square.on.square"),
        TimelineEvent(year: 2020, title: "Apple silicon: M1", detail: "The first Macs with Apple-designed chips and unified memory.", symbol: "cpu"),
        TimelineEvent(year: 2024, title: "Apple Vision Pro ships", detail: "Apple's first spatial computer, running visionOS.", symbol: "visionpro"),
        TimelineEvent(year: 2025, title: "Liquid Glass debuts", detail: "A new design language across every Apple platform, unveiled at WWDC25.", symbol: "drop"),
        TimelineEvent(year: 2026, title: "iPhone Duo unfolds", detail: "Apple's first foldable iPhone, with a 7.6-inch inner display.", symbol: "book.pages"),
    ]

    // MARK: Notes

    static let notes: [Note] = {
        var notes: [Note] = []
        notes += sprint.map { Note(title: $0.concept, body: $0.explanation, world: .swift) }
        notes += raceTiles.map { Note(title: "Is \($0.typeName) Sendable? \($0.isSendable ? "Yes" : "No")", body: $0.why, world: .swift) }
        notes += cards.map { Note(title: $0.answer, body: "\($0.task). \($0.detail) Example: \($0.snippet)", world: .frameworks) }
        notes += timeline.map { Note(title: "\($0.year): \($0.title)", body: $0.detail, world: .ecosystem) }
        return notes
    }()
}
