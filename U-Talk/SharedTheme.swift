import SwiftUI

extension Color {
    static let paleLime    = Color(hex: "E5F7CE")
    static let softCyan    = Color(hex: "C3F0FA")
    static let periwinkle  = Color(hex: "A9C9F9")
    static let mutedGreen  = Color(hex: "84B87F")
    static let forestGreen = Color(hex: "164A3E")
    static let offWhite    = Color(hex: "FAFCFB")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

struct UMascotView: View {
    var size: CGFloat = 100
    var showStickerBorder: Bool = false
    var isBlinking: Bool = false

    var body: some View {
        ZStack {
            if showStickerBorder {
                UShape()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: size * 0.16, lineCap: .round, lineJoin: .round))
                    .frame(width: size, height: size * 1.12)
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
            }

            UShape()
                .fill(Color.forestGreen)
                .frame(width: size, height: size * 1.12)

            VStack(spacing: size * 0.03) {
                HStack(spacing: size * 0.14) {
                    Capsule().fill(Color.paleLime).frame(width: size * 0.075, height: isBlinking ? size * 0.015 : size * 0.055)
                    Capsule().fill(Color.paleLime).frame(width: size * 0.075, height: isBlinking ? size * 0.015 : size * 0.055)
                }
                SmileArc().fill(Color.paleLime).frame(width: size * 0.17, height: size * 0.075)
            }
            .offset(y: size * 0.35)
        }
    }
}

struct UShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let strokeW = w * 0.31
        let radius = (w - strokeW) / 2
        path.move(to: CGPoint(x: strokeW / 2, y: strokeW / 2))
        path.addLine(to: CGPoint(x: strokeW / 2, y: h - radius - strokeW / 2))
        path.addArc(center: CGPoint(x: w / 2, y: h - radius - strokeW / 2), radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
        path.addLine(to: CGPoint(x: w - strokeW / 2, y: strokeW / 2))
        return path.strokedPath(StrokeStyle(lineWidth: strokeW, lineCap: .round, lineJoin: .round))
    }
}

/// Scalloped seal used behind the mascot, e.g. on the "You're all set" screen.
struct StampBadge: Shape {
    var points: Int = 16
    var innerRatio: CGFloat = 0.90

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX, cy = rect.midY
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        for i in 0 ..< (points * 2) {
            let angle = Double(i) * Double.pi / Double(points) - Double.pi / 2
            let r = (i % 2 == 0) ? outer : inner
            let pt = CGPoint(x: cx + r * CGFloat(cos(angle)),
                             y: cy + r * CGFloat(sin(angle)))
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}

struct SmileArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: rect.width / 2, y: rect.height * 1.9))
        path.closeSubpath()
        return path
    }
}

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TactileButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                }
            }
    }
}

struct OnboardingScaffold<Content: View>: View {
    let step: Int
    let totalSteps: Int
    let onBack: () -> Void
    let continueEnabled: Bool
    let onContinue: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color.offWhite.ignoresSafeArea()
            GeometryReader { geo in
                Circle().fill(Color.paleLime.opacity(0.75)).frame(width: 260, height: 260).position(x: geo.size.width * 0.78, y: 40)
                Circle().fill(Color.softCyan.opacity(0.85)).frame(width: 230, height: 230).position(x: 20, y: geo.size.height * 0.78)
            }.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold)).foregroundColor(.forestGreen)
                            .frame(width: 40, height: 40).background(Color.white).clipShape(Circle()).shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                    }.buttonStyle(TactileButtonStyle(scaleAmount: 0.9))

                    HStack(spacing: 6) {
                        ForEach(1...totalSteps, id: \.self) { index in
                            Capsule().fill(index <= step ? Color.forestGreen : Color.white).frame(height: 5)
                        }
                    }

                    Text("\(step) of \(totalSteps)").font(.system(size: 12, weight: .bold)).foregroundColor(.forestGreen)
                }.padding(.top, 12).padding(.bottom, 24)

                content
                Spacer()

                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Text("Continue").font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 56)
                    .background(continueEnabled ? Color.forestGreen : Color.forestGreen.opacity(0.35))
                    .clipShape(Capsule())
                }.buttonStyle(TactileButtonStyle()).disabled(!continueEnabled).padding(.bottom, 24)
            }.padding(.horizontal, 24)
        }
    }
}
