import SwiftUI

/// Diffuse color fields keep motion behind the content, without animating the list itself.
struct FlowingGradientBackground: View {
    enum Palette {
        case collected
        case history

        var colors: [Color] {
            switch self {
            case .collected:
                [Color(red: 0.22, green: 0.77, blue: 0.65),
                 Color(red: 0.28, green: 0.61, blue: 0.85),
                 Color(red: 0.94, green: 0.73, blue: 0.53)]
            case .history:
                [Color(red: 0.39, green: 0.57, blue: 0.91),
                 Color(red: 0.66, green: 0.46, blue: 0.83),
                 Color(red: 0.88, green: 0.57, blue: 0.65)]
            }
        }
    }

    let palette: Palette

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var isVisible = false

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(
                minimumInterval: 1.0 / 30,
                paused: reduceMotion || !isVisible || scenePhase != .active
            )) { context in
                let time = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                let colors = palette.colors
                let radius = max(geometry.size.width, geometry.size.height) * 0.8

                ZStack {
                    (isDark
                        ? Color(red: 0.055, green: 0.075, blue: 0.11)
                        : Color(red: 0.96, green: 0.97, blue: 0.98))

                    glow(
                        colors[0],
                        center: UnitPoint(
                            x: 0.15 + 0.18 * sin(time * .pi / 24),
                            y: 0.18 + 0.12 * cos(time * .pi / 28)
                        ),
                        radius: radius
                    )
                    glow(
                        colors[1],
                        center: UnitPoint(
                            x: 0.85 + 0.15 * cos(time * .pi / 30),
                            y: 0.48 + 0.18 * sin(time * .pi / 26)
                        ),
                        radius: radius * 0.85
                    )
                    glow(
                        colors[2],
                        center: UnitPoint(
                            x: 0.35 + 0.2 * sin(time * .pi / 32),
                            y: 0.95 + 0.12 * cos(time * .pi / 23)
                        ),
                        radius: radius * 0.75
                    )

                    LinearGradient(
                        colors: [.clear, (isDark ? Color.black : Color.white).opacity(0.18)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
    }

    private func glow(_ color: Color, center: UnitPoint, radius: CGFloat) -> some View {
        // Broad, fading stops produce a blurred appearance without a full-screen blur pass.
        RadialGradient(
            stops: [
                .init(color: color.opacity(isDark ? 0.30 : 0.34), location: 0),
                .init(color: color.opacity(isDark ? 0.13 : 0.16), location: 0.4),
                .init(color: color.opacity(0), location: 1)
            ],
            center: center,
            startRadius: 0,
            endRadius: radius
        )
    }
}
