import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Challenge Mode: spin for one of the five role-play scenes, then play it out.
/// The wheel is one Canvas — bezel, bulbs, wedges, hub and pointer are all drawn
/// there, so the whole thing scales with whatever frame it is given.
struct ChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tabBarVisibility) private var tabBar
    @AppStorage("userName") private var userName: String = ""

    @State private var rotation: Double = 0
    @State private var spinStart: Date?
    @State private var fromRot: Double = 0
    @State private var toRot: Double = 0
    @State private var landed: Int?
    @State private var landedAt: Date?
    @State private var startChallenge = false
    @State private var finishedSession = false

    private let deep = Color(red: 12/255, green: 33/255, blue: 28/255)
    private let bezel = Color(red: 22/255, green: 53/255, blue: 44/255)
    private let bezelHi = Color(red: 32/255, green: 72/255, blue: 61/255)
    private let lime = Color(red: 237/255, green: 252/255, blue: 214/255)
    private let cyan = Color(red: 204/255, green: 241/255, blue: 253/255)
    private let peri = Color(red: 183/255, green: 209/255, blue: 251/255)
    private let forest = Color(red: 39/255, green: 79/255, blue: 72/255)

    private let spinSeconds: Double = 3.6

    /// The five role-plays already defined in PracticeScenario, each with its
    /// own ambience. Add a sixth there and the wheel grows a sixth wedge.
    private var scenes: [PracticeScenario] { PracticeScenario.rolePlays }
    private var wedgeFills: [Color] { [lime, cyan, peri, lime, cyan] }
    private let shortLabels = ["CELEBRITY", "SUSPECT", "VILLAIN", "AGENT", "GAME"]

    private func shortLabel(_ i: Int) -> String {
        i < shortLabels.count ? shortLabels[i]
                              : scenes[i].title.uppercased()
                                    .replacingOccurrences(of: "THE ", with: "")
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backdrop(geo.size)

                VStack(spacing: 0) {
                    header
                    says.padding(.top, 4)
                    wheelCanvas.padding(.top, 2)
                    Spacer(minLength: 10)
                    resultCard
                    startButton.padding(.top, 12)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 18)

                backButton
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 14)
                    .padding(.top, 6)
            }
        }
        .background(deep.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { tabBar.hidden = true }
        .onDisappear { tabBar.hidden = false }
        // Straight into the conversation: the wheel has already told them the
        // scene, so ScenarioIntroView would only repeat it.
        .fullScreenCover(isPresented: $startChallenge) {
            if let landed {
                PracticeSessionContainer(scenario: scenes[landed],
                                         kind: .aiConversation,
                                         day: nil,
                                         userName: userName.isEmpty ? nil : userName) { didComplete in
                    finishedSession = didComplete
                    // Switch to the Roadmap underneath first, so the wheel isn't shown again on the way out.
                    if didComplete { NotificationCenter.default.post(name: .uTalkPracticeFinished, object: nil) }
                    startChallenge = false
                }
            }
        }
    }

    // MARK: chrome

    private func backdrop(_ size: CGSize) -> some View {
        ZStack {
            LinearGradient(colors: [deep, Color(red: 23/255, green: 54/255, blue: 46/255)],
                           startPoint: .top, endPoint: .bottom)
            // the spotlight beam
            EllipticalGradient(colors: [lime.opacity(0.15), .clear],
                               center: .top, startRadiusFraction: 0,
                               endRadiusFraction: 0.62)
        }
        .ignoresSafeArea()
    }

    private var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(lime)
                .frame(width: 42, height: 42)
                .background(lime.opacity(0.10), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        VStack(spacing: 5) {
            Text("CHALLENGE MODE")
                .font(.system(size: 10, weight: .heavy))
                .tracking(2.4)
                .foregroundStyle(lime.opacity(0.58))
            Text("Five scenes.\nOne spin.")
                .font(.system(size: 33, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(lime)
                .lineSpacing(-4)
        }
        .padding(.top, 34)
    }

    private var says: some View {
        HStack(spacing: 7) {
            AnimatedUMascot(style: .detective, onDark: true)
                .frame(width: 100, height: 100)
            SpeechBubble()
                .padding(.top, 14)
            Spacer(minLength: 0)
        }
    }

    // MARK: the wheel

    private var wheelCanvas: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                draw(&ctx, size: size, now: timeline.date)
            }
            .frame(height: 264)
            .contentShape(Rectangle())
            .onTapGesture { spin() }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, now: Date) {
        let d = min(size.width, size.height)
        let cx = size.width / 2, cy = size.height / 2
        let rOut = d * 0.487, rBez = d * 0.401, rHub = d * 0.151
        let rot = currentRotation(at: now)
        let flash = flashAmount(at: now)
        let settled = landed != nil && flash <= 0

        // bezel
        ctx.fill(circle(cx, cy, rOut), with: .color(bezel))
        ctx.stroke(circle(cx, cy, rOut - 1.5), with: .color(lime.opacity(0.16)), lineWidth: 2)
        ctx.stroke(circle(cx, cy, rBez + 4), with: .color(bezelHi), lineWidth: 5)

        // bulbs chasing round the bezel
        let beat = now.timeIntervalSinceReferenceDate
        for i in 0 ..< 16 {
            let a = (Double(i) / 16) * 360 - 90
            let x = cx + cos(a * .pi / 180) * d * 0.444
            let y = cy + sin(a * .pi / 180) * d * 0.444
            let phase = (beat * 1.6 + Double(i) / 16).truncatingRemainder(dividingBy: 1)
            var lit = 0.34 + 0.66 * pow(max(0, cos(phase * 2 * .pi)), 2)
            if flash > 0 { lit = max(lit, flash * (i % 2 == 1 ? 1 : 0.5)) }
            if lit > 0.6 {
                ctx.fill(circle(x, y, d * 0.030), with: .color(lime.opacity((lit - 0.6) * 0.22)))
            }
            ctx.fill(circle(x, y, d * 0.017), with: .color(lime.opacity(0.14 + lit * 0.86)))
        }

        // wedges
        let step = 360.0 / Double(scenes.count)
        for i in scenes.indices {
            let a0 = -90 + step * Double(i) + rot
            let slice = wedge(cx, cy, a0, a0 + step, rHub - 2, rBez)
            ctx.fill(slice, with: .color(wedgeFills[i % wedgeFills.count]))
            if settled && landed != i {
                ctx.fill(slice, with: .color(deep.opacity(0.34)))
            }
            if landed == i && flash > 0 {
                ctx.fill(slice, with: .color(.white.opacity(flash * 0.5)))
            }

            var divider = Path()
            divider.move(to: polar(cx, cy, a0, rHub - 2))
            divider.addLine(to: polar(cx, cy, a0, rBez))
            ctx.stroke(divider, with: .color(forest.opacity(0.28)), lineWidth: 2)

            // icon and name, riding with the wedge
            var g = ctx
            g.translateBy(x: cx, y: cy)
            g.rotate(by: .degrees(a0 + step / 2 + 90))
            g.draw(Text(Image(systemName: scenes[i].symbol))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(forest),
                   at: CGPoint(x: 0, y: -d * 0.329), anchor: .center)
            g.draw(Text(shortLabel(i))
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(forest),
                   at: CGPoint(x: 0, y: -d * 0.244), anchor: .center)
        }

        // hub
        ctx.fill(circle(cx, cy, rHub), with: .color(deep))
        ctx.stroke(circle(cx, cy, rHub - 5), with: .color(lime), lineWidth: 2)
        ctx.draw(Text("SPIN").font(.system(size: 14, weight: .black)).foregroundColor(lime),
                 at: CGPoint(x: cx, y: cy - 5), anchor: .center)
        ctx.draw(Text("\(scenes.count) SCENES")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(lime.opacity(0.55)),
                 at: CGPoint(x: cx, y: cy + 10), anchor: .center)

        // pointer, biting into the rim
        var arrow = Path()
        let tipY = cy - rOut + 4
        arrow.move(to: CGPoint(x: cx, y: tipY + 26))
        arrow.addLine(to: CGPoint(x: cx - 13, y: tipY - 4))
        arrow.addLine(to: CGPoint(x: cx + 13, y: tipY - 4))
        arrow.closeSubpath()
        ctx.fill(arrow, with: .color(lime))
        ctx.stroke(arrow, with: .color(deep), lineWidth: 3)
    }

    private func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }

    private func polar(_ cx: CGFloat, _ cy: CGFloat, _ deg: Double, _ r: CGFloat) -> CGPoint {
        CGPoint(x: cx + cos(deg * .pi / 180) * r, y: cy + sin(deg * .pi / 180) * r)
    }

    /// Sampled rather than built with addArc, so the sweep direction can't be
    /// flipped by the coordinate space.
    private func wedge(_ cx: CGFloat, _ cy: CGFloat,
                       _ a0: Double, _ a1: Double,
                       _ rIn: CGFloat, _ rOut: CGFloat) -> Path {
        var p = Path()
        let steps = 20
        for i in 0 ... steps {
            let a = a0 + (a1 - a0) * Double(i) / Double(steps)
            let pt = polar(cx, cy, a, rOut)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        for i in stride(from: steps, through: 0, by: -1) {
            p.addLine(to: polar(cx, cy, a0 + (a1 - a0) * Double(i) / Double(steps), rIn))
        }
        p.closeSubpath()
        return p
    }

    // MARK: result

    @ViewBuilder
    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let landed {
                Text("YOUR SCENE")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.8)
                    .foregroundStyle(lime.opacity(0.55))
                Text(scenes[landed].title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(lime)
                Text(scenes[landed].aiSummary)
                    .font(.system(size: 11.5))
                    .lineSpacing(1.5)
                    .foregroundStyle(lime.opacity(0.74))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(spinStart == nil ? "Tap the wheel to draw your scene." : "Spinning…")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(lime.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .padding(.horizontal, 17)
        .padding(.vertical, 15)
        .background(lime.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(lime.opacity(0.10), lineWidth: 1))
    }

    private var startButton: some View {
        Button {
            if landed == nil { spin() } else { startChallenge = true }
        } label: {
            Text(landed == nil ? "SPIN THE WHEEL" : "START CHALLENGE")
                .font(.system(size: 11.5, weight: .heavy))
                .tracking(1.7)
                .foregroundStyle(deep)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(lime, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: spinning

    /// Winds up from a standstill, then a long decel that runs past the mark
    /// and settles back. The time warp on the first fifth is what keeps the
    /// launch from leaping off the mark.
    private func easeOutBack(_ x: Double) -> Double {
        let w = x < 0.2 ? 0.2 * pow(x / 0.2, 1.8) : x
        let c1 = 1.70158 * 0.26, c3 = c1 + 1
        return 1 + c3 * pow(w - 1, 3) + c1 * pow(w - 1, 2)
    }

    private func currentRotation(at now: Date) -> Double {
        guard let start = spinStart else { return rotation }
        let p = min(1, now.timeIntervalSince(start) / spinSeconds)
        return fromRot + (toRot - fromRot) * easeOutBack(p)
    }

    private func flashAmount(at now: Date) -> Double {
        guard let at = landedAt else { return 0 }
        return max(0, 1 - now.timeIntervalSince(at) / 0.34)
    }

    /// Wedge `i` is centred at `-90 + step*i + step/2` before rotation and the
    /// pointer sits at the top, so the wheel must finish at `-(step*i + step/2)`.
    private func spin() {
        guard spinStart == nil else { return }
        landed = nil
        landedAt = nil
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        let pick = Int.random(in: 0 ..< scenes.count)
        let step = 360.0 / Double(scenes.count)
        let target = (360 - (step * Double(pick) + step / 2)).truncatingRemainder(dividingBy: 360)
        var delta = target - rotation.truncatingRemainder(dividingBy: 360)
        if delta < 0 { delta += 360 }

        fromRot = rotation
        toRot = rotation + delta + 360 * 4
        spinStart = Date()

        DispatchQueue.main.asyncAfter(deadline: .now() + spinSeconds) {
            rotation = toRot
            spinStart = nil
            landedAt = Date()
            withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                landed = pick
            }
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        }
    }
}

/// "SPIN THE WHEEL" with a tail pointing back at U.
private struct SpeechBubble: View {
    private let lime = Color(red: 237/255, green: 252/255, blue: 214/255)
    private let panel = Color(red: 30/255, green: 58/255, blue: 50/255)
    @State private var pop = false

    var body: some View {
        Text("SPIN THE WHEEL")
            .font(.system(size: 11, weight: .heavy))
            .tracking(1.1)
            .foregroundStyle(lime)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(panel, in: RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(panel)
                    .frame(width: 11, height: 11)
                    .rotationEffect(.degrees(45))
                    .offset(x: -4)
            }
            .scaleEffect(pop ? 1.06 : 1, anchor: .leading)
            .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)
                        .delay(1.4), value: pop)
            .onAppear { pop = true }
    }
}

#Preview {
    NavigationStack { ChallengeView() }
}
