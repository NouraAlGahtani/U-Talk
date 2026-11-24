import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Shown once when the user finishes the last day of their roadmap: on a green screen that fades in,
/// the U rises gently, then "Congratulations!", with soft confetti drifting down.
/// Triggered by PracticeProgress (sets `pendingKey`), shown by MainTabView.
struct CelebrationView: View {
    static let pendingKey = "utalk.celebrationPending"

    var onDone: () -> Void

    @AppStorage("userName") private var userName: String = ""
    @State private var start = Date()
    @State private var showCard = false
    @State private var showMascot = false
    @State private var showText = false
    @State private var showButton = false
    @State private var popBump = false      // the U's little jump each time it pops confetti
    /// Two party-popper bursts: left arm, then right arm.
    private static let pops: [(delay: Double, lean: Double, dx: CGFloat)] = [
        (delay: 0.95, lean: -0.55, dx: -52),
        (delay: 1.35, lean: 0.55, dx: 52)
    ]

    private let forest = Color(red: 39/255, green: 79/255, blue: 72/255)
    private let lime = Color(red: 237/255, green: 252/255, blue: 214/255)

    private var name: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "" : ", \(trimmed)"
    }

    var body: some View {
        ZStack {
            // Full-screen green like the first version, but it fades in slowly (see MainTabView).
            forest.opacity(0.94).ignoresSafeArea()

            ConfettiBurst(start: start)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Content rises gently into place (no card around it)
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(lime).frame(width: 150, height: 150)
                    AnimatedUMascot(style: .excitedWink)
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                }
                // party hat + a confetti popper in each arm, moving with the U's hops
                .overlay {
                    PartyProps(mascotSize: 150)
                        .frame(width: 280, height: 280)
                        .allowsHitTesting(false)
                }
                .scaleEffect(popBump ? 1.08 : 1)
                // The U pops confetti out of the top of its arms, like party poppers: left, then right.
                .overlay {
                    UConfettiPop(start: start, pops: Self.pops)
                        .frame(width: 380, height: 380)
                        .allowsHitTesting(false)
                }
                .scaleEffect(showMascot ? 1 : 0.85)
                .opacity(showMascot ? 1 : 0)
                .padding(.top, 8)

                VStack(spacing: 8) {
                    Text("Congratulations\(name)!")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(lime)
                    Text("You finished every day of your roadmap.\nThat took real courage. 💚")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(lime.opacity(0.85))
                }
                .opacity(showText ? 1 : 0)

                Button {
                    onDone()
                } label: {
                    Text("Yay!")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(forest)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(lime, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
                .opacity(showButton ? 1 : 0)
            }
            .padding(24)
            .padding(.horizontal, 26)
            .offset(y: showCard ? 0 : 60)
            .opacity(showCard ? 1 : 0)
        }
        .onAppear {
            start = Date()
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            #endif
            // one thing at a time, slowly
            withAnimation(.spring(response: 0.9, dampingFraction: 0.85).delay(0.2)) { showCard = true }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6)) { showMascot = true }
            withAnimation(.easeOut(duration: 0.6).delay(1.0)) { showText = true }
            withAnimation(.easeOut(duration: 0.5).delay(1.6)) { showButton = true }
            // a little hop with each pop
            for pop in Self.pops {
                let delay: Double = pop.delay
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) { popBump = true }
                    #if canImport(UIKit)
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)
                    #endif
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { popBump = false }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

/// Confetti popped out of the U: each pop throws pieces up and out in a cone (tilted by `lean`),
/// then they fall with gravity, tumble and fade. Drawn around the U (origin = top of its arms).
private struct UConfettiPop: View {
    let start: Date
    let pops: [(delay: Double, lean: Double, dx: CGFloat)]

    private let colors: [Color] = [
        Color(red: 237/255, green: 252/255, blue: 214/255),
        Color(red: 183/255, green: 209/255, blue: 251/255),
        Color(red: 204/255, green: 241/255, blue: 253/255),
        Color(red: 150/255, green: 189/255, blue: 136/255),
        Color(red: 232/255, green: 195/255, blue: 90/255)
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t: Double = timeline.date.timeIntervalSince(start)
                for k in 0..<pops.count {
                    drawPop(&ctx, size: size, t: t, k: k)
                }
            }
        }
    }

    // Split into small, explicitly typed steps so the Swift compiler type-checks it quickly.
    private func drawPop(_ ctx: inout GraphicsContext, size: CGSize, t: Double, k: Int) {
        let pop = pops[k]
        let tt: Double = t - pop.delay
        guard tt > 0, tt < 2.4 else { return }
        let originX: CGFloat = size.width / 2 + pop.dx
        let originY: CGFloat = size.height / 2 - 80
        let fade: Double = tt < 1.4 ? 1.0 : max(0.0, 1.0 - (tt - 1.4))
        let drag: Double = 1.0 - min(0.5, tt * 0.25)          // slows down a little in the air
        let gravityDrop: Double = 260.0 * tt * tt

        for i in 0..<34 {
            let r1: Double = rand(i, 10 + k)
            let r2: Double = rand(i, 20 + k)
            let r3: Double = rand(i, 30 + k)
            let angle: Double = -Double.pi / 2 + pop.lean + (r1 - 0.5) * 1.3
            let speed: Double = 240.0 + r2 * 260.0
            let travel: Double = speed * tt * drag
            let dx: Double = cos(angle) * travel
            let dy: Double = sin(angle) * travel + gravityDrop
            let spin: Double = tt * (5.0 + r3 * 7.0) + Double(i)
            let squeeze: Double = abs(cos(spin * 0.7)) * 0.8 + 0.2

            var p = ctx
            p.opacity = fade
            p.translateBy(x: originX + CGFloat(dx), y: originY + CGFloat(dy))
            p.rotate(by: .radians(spin))
            p.scaleBy(x: CGFloat(squeeze), y: 1)
            piece(&p, wide: i.isMultiple(of: 3), color: colors[(i + k) % colors.count])
        }
    }

    private func piece(_ p: inout GraphicsContext, wide: Bool, color: Color) {
        if wide {
            p.fill(Path(roundedRect: CGRect(x: -5, y: -2.5, width: 10, height: 5), cornerRadius: 1.5),
                   with: .color(color))
        } else {
            p.fill(Path(ellipseIn: CGRect(x: -3.5, y: -3.5, width: 7, height: 7)), with: .color(color))
        }
    }

    private func rand(_ i: Int, _ salt: Int) -> Double {
        let v = sin(Double(i * 127 + salt * 311) * 12.9898) * 43758.5453
        return v - floor(v)
    }
}

/// A gentle confetti shower that fades in and drifts down from the top.
private struct ConfettiBurst: View {
    let start: Date

    private let colors: [Color] = [
        Color(red: 237/255, green: 252/255, blue: 214/255),   // pale lime
        Color(red: 183/255, green: 209/255, blue: 251/255),   // periwinkle
        Color(red: 204/255, green: 241/255, blue: 253/255),   // soft cyan
        Color(red: 150/255, green: 189/255, blue: 136/255),   // muted green
        Color(red: 232/255, green: 195/255, blue: 90/255)     // gold
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t: Double = timeline.date.timeIntervalSince(start)
                // shower: keeps falling softly from the top
                for i in 0..<28 {
                    let r1: Double = rand(i, 4)
                    let r2: Double = rand(i, 5)
                    let fall: Double = 0.07 + r2 * 0.05
                    let phase: Double = (t * fall + r1).truncatingRemainder(dividingBy: 1)
                    let sway: Double = sin(t * 1.5 + Double(i)) * 14.0
                    let x: CGFloat = size.width * CGFloat(rand(i, 6)) + CGFloat(sway)
                    let y: CGFloat = size.height * CGFloat(phase) - 10
                    let fadeIn: Double = min(1.0, max(0.0, (t - 0.9) / 1.5)) * 0.85
                    var c = ctx
                    c.opacity = fadeIn
                    piece(&c, x, y, t * 3 + Double(i), colors[(i + 2) % colors.count], wide: i.isMultiple(of: 2))
                }
            }
        }
    }

    private func piece(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ spin: Double,
                       _ color: Color, wide: Bool) {
        var p = ctx
        p.translateBy(x: x, y: y)
        p.rotate(by: .radians(spin))
        let squeeze: Double = abs(cos(spin * 0.7)) * 0.8 + 0.2
        p.scaleBy(x: CGFloat(squeeze), y: 1)   // tumbling
        if wide {
            p.fill(Path(roundedRect: CGRect(x: -5, y: -2.5, width: 10, height: 5), cornerRadius: 1.5), with: .color(color))
        } else {
            p.fill(Path(ellipseIn: CGRect(x: -3.5, y: -3.5, width: 7, height: 7)), with: .color(color))
        }
    }

    /// Stable pseudo-random number in 0..<1 for piece `i`.
    private func rand(_ i: Int, _ salt: Int) -> Double {
        let v = sin(Double(i * 127 + salt * 311) * 12.9898) * 43758.5453
        return v - floor(v)
    }
}

#Preview {
    CelebrationView { }
}


/// Birthday hat on top of the U and a party popper in each arm, drawn with the same hop and tilt
/// as AnimatedUMascot's .excitedWink (same clock and formulas), so they move together.
private struct PartyProps: View {
    let mascotSize: CGFloat

    private let forest = Color(red: 39/255, green: 79/255, blue: 72/255)
    private let lime = Color(red: 237/255, green: 252/255, blue: 214/255)
    private let periwinkle = Color(red: 183/255, green: 209/255, blue: 251/255)
    private let gold = Color(red: 232/255, green: 195/255, blue: 90/255)
    private let coral = Color(red: 240/255, green: 128/255, blue: 110/255)

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t: Double = timeline.date.timeIntervalSinceReferenceDate
                draw(&ctx, size: size, t: t)
            }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let s: CGFloat = mascotSize * 0.62                  // the U's width inside .excitedWink
        let cx: CGFloat = size.width / 2
        let cy: CGFloat = size.height / 2
        // same motion as .excitedWink
        let hop: Double = t.truncatingRemainder(dividingBy: 1.4) / 1.4
        let jumpAmount: Double = hop < 0.48 ? sin(hop / 0.48 * Double.pi) : 0
        let jump: CGFloat = -CGFloat(jumpAmount) * s * 0.072
        let tip: Double = sin(t * 2 * Double.pi / 1.4) * 0.055

        var g = ctx
        g.translateBy(x: 0, y: jump)
        g.translateBy(x: cx, y: cy)
        g.rotate(by: .radians(tip))
        g.translateBy(x: -cx, y: -cy)

        let armTop: CGFloat = cy - s * 0.50
        popper(&g, base: CGPoint(x: cx - s * 0.345, y: armTop), angle: -0.55, s: s)
        popper(&g, base: CGPoint(x: cx + s * 0.345, y: armTop), angle: 0.55, s: s)
        hat(&g, cx: cx, baseY: cy - s * 0.47, s: s, t: t)
    }

    /// Striped cone hat with a pompom, sitting across the tops of the U's arms.
    private func hat(_ g: inout GraphicsContext, cx: CGFloat, baseY: CGFloat, s: CGFloat, t: Double) {
        var h = g
        h.translateBy(x: cx, y: baseY)
        h.rotate(by: .radians(0.12))
        let halfBase: CGFloat = s * 0.34
        let height: CGFloat = s * 0.62
        var cone = Path()
        cone.move(to: CGPoint(x: -halfBase, y: 0))
        cone.addLine(to: CGPoint(x: 0, y: -height))
        cone.addLine(to: CGPoint(x: halfBase, y: 0))
        cone.closeSubpath()
        h.fill(cone, with: .color(periwinkle))
        // stripes
        var striped = h
        striped.clip(to: cone)
        for i in 0..<4 {
            let y: CGFloat = -height * (0.18 + 0.22 * CGFloat(i))
            var stripe = Path()
            stripe.move(to: CGPoint(x: -halfBase, y: y + s * 0.05))
            stripe.addLine(to: CGPoint(x: halfBase, y: y - s * 0.05))
            striped.stroke(stripe, with: .color(i.isMultiple(of: 2) ? gold : coral), lineWidth: s * 0.055)
        }
        // brim
        h.fill(Path(roundedRect: CGRect(x: -halfBase - s * 0.02, y: -s * 0.035, width: (halfBase + s * 0.02) * 2,
                                        height: s * 0.06), cornerRadius: s * 0.03),
               with: .color(lime))
        // pompom, bouncing a little
        let wobble: CGFloat = CGFloat(sin(t * 9)) * s * 0.012
        let r: CGFloat = s * 0.075
        h.fill(Path(ellipseIn: CGRect(x: -r + wobble, y: -height - r, width: r * 2, height: r * 2)),
               with: .color(coral))
    }

    /// Party popper: a gold cone held in the arm, mouth pointing up and outwards.
    private func popper(_ g: inout GraphicsContext, base: CGPoint, angle: Double, s: CGFloat) {
        var p = g
        p.translateBy(x: base.x, y: base.y)
        p.rotate(by: .radians(angle))
        let length: CGFloat = s * 0.42
        let mouth: CGFloat = s * 0.15
        var cone = Path()
        cone.move(to: CGPoint(x: -s * 0.03, y: 0))
        cone.addLine(to: CGPoint(x: -mouth, y: -length))
        cone.addLine(to: CGPoint(x: mouth, y: -length))
        cone.addLine(to: CGPoint(x: s * 0.03, y: 0))
        cone.closeSubpath()
        p.fill(cone, with: .color(gold))
        var bands = p
        bands.clip(to: cone)
        for i in 0..<3 {
            let y: CGFloat = -length * (0.25 + 0.25 * CGFloat(i))
            var band = Path()
            band.move(to: CGPoint(x: -mouth, y: y))
            band.addLine(to: CGPoint(x: mouth, y: y))
            bands.stroke(band, with: .color(forest.opacity(0.55)), lineWidth: s * 0.03)
        }
        p.fill(Path(ellipseIn: CGRect(x: -mouth, y: -length - s * 0.035, width: mouth * 2, height: s * 0.07)),
               with: .color(coral))
    }
}
