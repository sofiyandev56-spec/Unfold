# Design research behind Unfold

This is the research we did before writing code, and the decision each finding led to. Every decision below is visible in the app.

## 1. Apple's foldable platform (iPhone Duo, iOS 27.1)

**What we found**

- iPhone Duo was announced on 9 September 2026 with a 5.4-inch cover display and a 7.6-inch inner display that share one aspect ratio, a titanium hinge, Touch ID in the side button, and A20 Pro. It ships with iOS 27.1. ([Apple Newsroom](https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/))
- In the Xcode 27.1 Simulator the cover display is 466 × 678 pt and the inner display is 669 × 951 pt (read from the device profile in `/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone Duo.simdevicetype`). The inner panel folds across its long side, so in portrait the crease is horizontal (laptop) and in landscape it is vertical (book).
- The iOS 27.1 SDK adds real hinge and fold APIs, which we read straight from the SDK's interface files:
  - `View.onHingeChange(_:)` delivers `DeviceHingeContext`, whose `hinge` has an `angle` and a `status` (closed, partially open, fully open). UIKit has the same through `UIHingeInteraction`.
  - `GeometryProxy.reservedRegions(kind: .division)` returns the fold as a reserved region, and `.occlusion` returns the inner camera.
  - `ArrangementView` with `.split` and `.overlay` styles lays out two views around the fold.
- The Human Interface Guidelines for iPhone Duo ask apps to design around size classes rather than per pose, to handle the fold by **displacement** (move elements, don't redesign them), to keep controls and hierarchy identical across poses, and to put glanceable content on the raised half and controls on the resting half. ([HIG summary](https://www.sagarunagar.com/blog/iphone-duo-human-interface-guidelines))

**What we did**

- `FoldState` reads the real hinge through `onHingeChange`, and the iPhone Duo Simulator reports it live ("Live from iPhone Duo · 0°" on the Journey screen).
- Games use the hinge only while the inner display is open. When the phone is shut, people are using the cover display, so every game falls back to touch.
- `FoldSplit` places two views on either side of the crease, read from `reservedRegions(kind: .division)`. That is displacement: the same views, moved.
- A **presenter hinge** drives the same `FoldState` from a Liquid Glass slider, so every fold interaction can be demonstrated on any iPhone, in the Simulator, or on a projector.
- Each game turns the fold into the mechanic itself: the card flips on the hinge's own axis, the hinge angle is the year dial, and the crease is Swift's isolation boundary.

## 2. Liquid Glass

**What we found** ([Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass), WWDC25 "Meet Liquid Glass")

- Liquid Glass "forms a distinct functional layer for controls and navigation elements" that floats above content.
- "Avoid overusing Liquid Glass effects… Limit these effects to the most important functional elements."
- Avoid layering glass on glass; combine custom glass shapes in a `GlassEffectContainer` so they render efficiently and morph.
- Prefer system components and the new `.glass` and `.glassProminent` button styles to hand-made effects; use scroll edge effects so controls stay legible over content.
- Use concentric, rounded shapes that echo the hardware.

**What we did**

- Glass appears **only on the navigation and control layer**: the system tab bar (which iOS moves to the right edge on iPhone Duo's cover display), toolbars, the game HUD, the Coach composer, and the presenter hinge.
- Content cards are solid surfaces. We never put glass on glass.
- HUD pieces sit in `GlassEffectContainer`s; buttons use `.glass` and `.glassProminent`; screens use `scrollEdgeEffectStyle(.soft)` and `tabBarMinimizeBehavior(.onScrollDown)`.
- Cards use continuous corner radii that nest concentrically (34 → 24 → 18).

## 3. Colour: Apple's rules and the psychology

**Apple's guidance** ([HIG: Color](https://developer.apple.com/design/human-interface-guidelines/color))

- Use colour sparingly and give each colour one consistent meaning.
- Don't rely on colour alone to carry information.
- Keep a single key colour for interactive elements, test in dark mode and with increased contrast, and use Display P3 where it helps.

**Research on colour and learning**

- Mehta and Zhu (*Science*, 2009) found that red improves performance on detail-oriented tasks by priming avoidance, while blue improves creative tasks by priming approach motivation.
- Elliot and colleagues (*Journal of Experimental Psychology: General*, 2007) found that brief exposure to red before an achievement test lowered scores, which they attribute to an association with failure.
- A 2024 study of a language-learning app found colour had a significant positive effect on learning interest and motivation. ([INJECT journal](https://ejournal.uinsalatiga.ac.id/index.php/inject/article/view/6826))
- The wider claims about specific colours (blue calms, green focuses) come mostly from design blogs, so we treated them as weak evidence.

**What we did: a semantic palette**

| Colour | Meaning in Unfold | Why |
|---|---|---|
| Blue `#3D8CFF` | Only things you can tap | Apple's convention for interactivity; blue primes approach |
| Orange `#FF7333` | The Swift world | Swift's own brand colour; warm colours read as energy and momentum for practice |
| Cyan `#40CCEB` | The Frameworks world | A cool, calm colour for building and recall |
| Purple `#AD73FF` | The Ecosystem world | Heritage and imagination, for Apple's history |
| Green `#33D66B` | Correct | Universal success signal, always paired with a checkmark |
| Red `#FF4A4A` | Incorrect, for a moment only | Flashes, then gives way to the explanation, because lingering red hurts test performance |
| Intelligence gradient | Only when Apple Intelligence is speaking | A colour that means one thing: "the on-device model wrote this" |

- The app is dark-only, like Apple Fitness: the rings and P3 colours read best on true-black OLED, and dark backgrounds save power on large displays.
- Every coloured state also has a shape or symbol (✓, ✕, a lock, a crown), so colour is never the only signal.

## 4. Typography and motion

- SF Pro Rounded for display type (friendly and game-like, as in Fitness and Game Center), SF Pro for body, and SF Mono with Xcode's dark-theme colours for code.
- Springs everywhere (`.smooth`, `.bouncy`, interactive springs on the hinge), zoom navigation transitions from game tiles, `numericText` for scores, and symbol effects. Mesh gradients slow down or stop when Reduce Motion is on.

## 5. Learning science

- **Retrieval practice and immediate feedback**: every game asks before it tells, and every mistake explains itself right away.
- **Spaced repetition**: Fold & Flip uses Leitner boxes, so cards you miss come back first.
- **Mastery, not points**: three rings, one per world, track a moving average of accuracy.
- **A tutor that knows your mistakes**: Coach's debrief after each round reads your misses, and its answers are grounded in Unfold's curriculum, so the on-device model can explain APIs newer than its training, like `onHingeChange`.
