import SwiftUI
import UIKit

// MARK: - U-TALK design tokens (from "colors etc.png" component system)

enum UTalk {
    static let paleLime   = Color(utalkHex: 0xEDFCD6)
    static let softCyan   = Color(utalkHex: 0xCCF1FD)
    static let periwinkle = Color(utalkHex: 0xB7D1FB)
    static let mutedGreen = Color(utalkHex: 0x96BD88)
    static let forest     = Color(utalkHex: 0x274F48)

    // Supporting neutrals (not in the swatch table; picked to match the mockups)
    static let ink   = Color(utalkHex: 0x1E2B28)
    static let muted = Color(utalkHex: 0x51605B)
    static let track = Color(utalkHex: 0xE4E8E6)

    /// Serif headline font. Swap for the team's custom serif once it is added to the project.
    static func serif(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func clock(_ t: TimeInterval) -> String {
        let s = max(0, Int(t.rounded()))
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    static func duration(_ t: TimeInterval) -> String {
        let s = max(0, Int(t.rounded()))
        return s < 60 ? "\(s) sec" : "\(s / 60) min \(s % 60) sec"
    }
}

extension Color {
    init(utalkHex hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - Shapes

/// Scalloped circle used for the DAY badge and the U logo on the feedback screen.
struct ScallopShape: Shape {
    var bumps = 14
    var depth: CGFloat = 0.06

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        let steps = 360
        for i in 0...steps {
            let t = Double(i) / Double(steps) * 2 * .pi
            let rr = r * (1 - depth * CGFloat((1 - cos(Double(bumps) * t)) / 2))
            let pt = CGPoint(x: c.x + rr * CGFloat(cos(t)), y: c.y + rr * CGFloat(sin(t)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Small components

struct UTalkBackButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(UTalk.ink)
                .frame(width: 44, height: 44)
                .background(Color.white, in: Circle())
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
}

struct DayBadge: View {
    let day: Int
    var body: some View {
        ZStack {
            ScallopShape().fill(Color.white)
            ScallopShape().stroke(UTalk.ink.opacity(0.75), lineWidth: 1)
            VStack(spacing: -2) {
                Text("DAY").font(.system(size: 9, weight: .semibold)).tracking(0.6)
                Text("\(day)").font(UTalk.serif(24))
            }
            .foregroundStyle(UTalk.ink)
        }
        .frame(width: 66, height: 66)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Day \(day)")
    }
}

struct ULogo: View {
    var size: CGFloat = 100
    var scalloped = false
    var body: some View {
        ZStack {
            if scalloped {
                ScallopShape(bumps: 16, depth: 0.05).fill(UTalk.paleLime)
            } else {
                Circle().fill(UTalk.paleLime)
            }
            // U-TALK mark (Assets.xcassets/ULogoMark). Falls back to a "U" if the asset is missing.
            if UIImage(named: "ULogoMark") != nil {
                Image("ULogoMark")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size * 0.5, height: size * 0.58)
            } else {
                Text("U")
                    .font(.system(size: size * 0.42, weight: .heavy, design: .rounded))
                    .foregroundStyle(UTalk.forest)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct TagPill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(0.3)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(UTalk.forest, in: Capsule())
    }
}

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(UTalk.ink)
    }
}

struct NumberedRow: View {
    let index: Int
    let text: String
    let tint: Color
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(UTalk.serif(13))
                .foregroundStyle(UTalk.ink)
                .frame(width: 26, height: 26)
                .background(tint, in: Circle())
                .overlay(Circle().stroke(UTalk.forest.opacity(0.12)))
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(UTalk.ink)
        }
    }
}

struct GoalChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(UTalk.ink)
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(Color.white, in: Capsule())
            .overlay(Capsule().stroke(UTalk.track, lineWidth: 1))
    }
}

struct UTalkPrimaryButton: View {
    let title: String
    var enabled = true
    var showsArrow = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title).font(.system(size: 16, weight: .semibold))
                if showsArrow && enabled { Image(systemName: "arrow.right") }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(enabled ? Color.white : UTalk.forest.opacity(0.75))
            .background(enabled ? UTalk.forest : UTalk.track, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// Five-segment level indicator. `level == nil` renders an empty (not analyzed) state.
struct LevelBars: View {
    let level: Int?
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(fill(i))
                    .frame(width: 8, height: 20)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(level.map { "\($0) of 5" } ?? "Not analyzed")
    }
    private func fill(_ i: Int) -> Color {
        guard let level else { return UTalk.track }
        return i < level ? UTalk.forest : UTalk.track
    }
}

/// Decorative waveform. It animates while `active` but does NOT reflect real audio levels.
struct WaveformBars: View {
    var active: Bool
    var color: Color
    var count = 25
    var maxHeight: CGFloat = 30

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !active)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 4) {
                ForEach(0..<count, id: \.self) { i in
                    Capsule().fill(color).frame(width: 3, height: barHeight(i, t))
                }
            }
            .frame(height: maxHeight)
        }
        .accessibilityHidden(true)
    }

    private func barHeight(_ i: Int, _ t: Double) -> CGFloat {
        let base = 0.3 + 0.7 * abs(sin(Double(i) * 0.9))
        let wobble = active ? 0.45 + 0.55 * abs(sin(t * 5 + Double(i) * 0.7)) : 0.6
        return max(4, maxHeight * CGFloat(base * wobble))
    }
}

/// Wrapping layout for goal chips.
struct UTalkFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

extension View {
    /// Soft cyan circle peeking in from the left edge, as in the mockups.
    func utalkCyanBlob(size: CGFloat = 340, offset: CGSize = CGSize(width: -200, height: -110)) -> some View {
        background(alignment: .bottomLeading) {
            Circle()
                .fill(UTalk.softCyan.opacity(0.85))
                .frame(width: size, height: size)
                .offset(offset)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
