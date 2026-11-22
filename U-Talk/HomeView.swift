import SwiftUI

struct HomeView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("currentPracticeDay") private var currentDay: Int = 1
    @AppStorage("practiceMinutesThisWeek") private var practiceMinutesThisWeek: Int = 0
    @AppStorage("completedToday") private var completedToday: Bool = false
    @AppStorage("selectedScenario") private var selectedScenario: String = ""
    @AppStorage(RoadmapPlan.focusKey) private var roadmapFocus: String = ""
    
    let forestGreen = Color(red: 39/255, green: 79/255, blue: 72/255)
    let paleLime = Color(red: 237/255, green: 252/255, blue: 214/255)
    let softCyan = Color(red: 204/255, green: 241/255, blue: 253/255)
    let periwinkle = Color(red: 183/255, green: 209/255, blue: 251/255)
    
    let days = ["M", "T", "W", "T", "F", "S", "S"]
    
    private var displayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "friend" : trimmed
    }
    
    private var initialLetter: String {
        String(displayName.prefix(1)).uppercased()
    }
    
    private var completedSessionsCount: Int {
        max(0, currentDay - 1)
    }
    
    /// Today's lesson from the roadmap plan (built from the onboarding answers), same as RoadmapView.
    private var currentLesson: RoadmapLesson {
        RoadmapPlan.lesson(day: currentDay, focus: roadmapFocus)
    }
    
    var body: some View {
        GeometryReader { screen in
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()
                
                softCyan
                    .frame(height: 270 + screen.safeAreaInsets.top)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea(edges: .top)
                
                ScrollView {
                    VStack(spacing: 0) {
                        ZStack(alignment: .top) {
                            Color.white
                            
                            softCyan
                                .frame(height: 350)
                                .frame(maxHeight: .infinity, alignment: .top)
                            
                            Circle()
                                .fill(periwinkle)
                                .frame(width: 210, height: 210)
                                .position(x: screen.size.width - 5, y: 265)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Spacer()
                                    NavigationLink {
                                        Text("Profile Page")
                                    } label: {
                                        Text(initialLetter)
                                            .font(.system(size: 22, weight: .bold, design: .serif))
                                            .foregroundStyle(forestGreen)
                                            .frame(width: 48, height: 48)
                                            .background(.white, in: Circle())
                                    }
                                }
                                .padding(.top, 12)
                                
                                Text("Speak freely\ntoday, \(displayName).")
                                    .font(.system(size: 42, weight: .bold, design: .serif))
                                    .foregroundStyle(forestGreen)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.7)
                                    .offset(y: -15)
                                
                                Spacer().frame(height: 30)
                                
                                VStack(spacing: 0) {
                                    AnimatedUMascot(style: .excitedWink)
                                        .frame(width: 70, height: 70)
                                        .frame(width: 100, height: 100)
                                        .background(paleLime, in: Circle())
                                        .padding(.top, -45)
                                    
                                    Text("Day \(currentDay) · about \(currentLesson.duration)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(forestGreen)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 7)
                                        .background(softCyan, in: Capsule())
                                        .padding(.top, 12)
                                    
                                    Text(currentLesson.title)
                                        .font(.system(size: 31, weight: .bold, design: .serif))
                                        .foregroundStyle(forestGreen)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                        .padding(.top, 12)
                                    
                                    Text(currentLesson.subtitle)
                                        .font(.system(size: 15))
                                        .foregroundStyle(forestGreen.opacity(0.85))
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.top, 8)
                                    
                                    NavigationLink {
                                        PracticeSelectionView(day: currentDay, scenario: currentLesson.title)
                                    } label: {
                                        HStack(spacing: 10) {
                                            Text("Practice today")
                                            Image(systemName: "mic")
                                        }
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(forestGreen, in: Capsule())
                                    }
                                    .padding(.top, 18)
                                    .padding(.horizontal, 18)
                                }
                                .padding(.horizontal, 18)
                                .padding(.bottom, 24)
                                .frame(maxWidth: .infinity)
                                .background {
                                    GeometryReader { geometry in
                                        Path { path in
                                            let w = geometry.size.width
                                            let h = geometry.size.height
                                            
                                            path.move(to: CGPoint(x: 0, y: 125))
                                            path.addCurve(
                                                to: CGPoint(x: w, y: 125),
                                                control1: CGPoint(x: w * 0.18, y: -30),
                                                control2: CGPoint(x: w * 0.82, y: -30)
                                            )
                                            path.addLine(to: CGPoint(x: w, y: h - 30))
                                            path.addQuadCurve(
                                                to: CGPoint(x: w - 30, y: h),
                                                control: CGPoint(x: w, y: h)
                                            )
                                            path.addLine(to: CGPoint(x: 30, y: h))
                                            path.addQuadCurve(
                                                to: CGPoint(x: 0, y: h - 30),
                                                control: CGPoint(x: 0, y: h)
                                            )
                                            path.closeSubpath()
                                        }
                                        .fill(.white)
                                        .shadow(color: forestGreen.opacity(0.06), radius: 10, y: 4)
                                    }
                                }
                                .padding(.top, 25)
                            }
                            .padding(.horizontal, 24)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(alignment: .center, spacing: 7) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(completedSessionsCount)")
                                    .font(.system(size: 50, weight: .bold, design: .serif))
                                Text("day\nstreak")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(forestGreen)
                            
                            Spacer(minLength: 0)
                            
                            HStack(spacing: 3) {
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    VStack(spacing: 5) {
                                        ZStack {
                                            Circle()
                                                .fill(dayIndex < completedSessionsCount ? paleLime : Color.gray.opacity(0.16))
                                                .frame(width: 30, height: 30)
                                            
                                            if dayIndex < completedSessionsCount {
                                                Image(systemName: "flame.fill")
                                                    .font(.system(size: 17))
                                                    .foregroundStyle(.orange)
                                            } else if dayIndex == completedSessionsCount {
                                                Circle()
                                                    .strokeBorder(
                                                        forestGreen,
                                                        style: StrokeStyle(lineWidth: 2, dash: [3, 3])
                                                    )
                                                    .frame(width: 30, height: 30)
                                            }
                                        }
                                        Text(days[dayIndex])
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(forestGreen)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(.top, 22)
                        .padding(.horizontal, 20)

                        // ── Challenge Mode button ──────────────────────
                        NavigationLink {
                            ChallengeView()
                        } label: {
                            HStack(spacing: 16) {
                                AnimatedUMascot(style: .blaze)
                                    .frame(width: 56, height: 56)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Challenge Mode")
                                        .font(.system(size: 17, weight: .bold, design: .serif))
                                        .foregroundStyle(forestGreen)
                                    Text("Push your limits.")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(forestGreen.opacity(0.72))
                                }

                                Spacer(minLength: 0)

                                Image(systemName: "arrow.right")
                                    .foregroundStyle(forestGreen)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 13)
                            .frame(maxWidth: .infinity)
                            .background(softCyan, in: RoundedRectangle(cornerRadius: 22))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        NavigationLink {
                            AllSessionsView()
                        } label: {
                            practiceHistoryCard
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 64)
                        .padding(.horizontal, 20)
                    }
                    // Opaque, so the fixed cyan band behind the ScrollView stays behind
                    // the header instead of showing through rows that scroll over it.
                    .background(Color.white)
                }
                .scrollIndicators(.hidden)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    /// Home's one entry point into session history. The clock mark bleeds off
    /// the corner to give the card weight without stating a figure.
    var practiceHistoryCard: some View {
        ZStack(alignment: .bottomLeading) {
            Color.clear

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 124, weight: .ultraLight))
                .foregroundStyle(forestGreen.opacity(0.16))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 30, y: 32)
                .allowsHitTesting(false)

            HStack(alignment: .bottom, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Practice history")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("Every session, start to finish.")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(forestGreen.opacity(0.72))
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
            }
            .padding(16)
        }
        .foregroundStyle(forestGreen)
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(paleLime)
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
    
}

// MARK: - Animated U mascot

/// Effects layered over the project's own `UShape` and `SmileArc`, so the character
/// here is the same U used on the onboarding screens. Every measurement is a multiple
/// of `s`, the U's width, and the eye and smile positions mirror `UMascotView`.
private enum UMFX {
    static let ember = Color(red: 1.0, green: 150/255, blue: 26/255)
    static let flame = Color(red: 1.0, green: 228/255, blue: 92/255)

    static let eyeDX:  CGFloat = 0.1075   // eye centre, out from the middle
    static let eyeY:   CGFloat = 0.2975   // eye centre, down from the middle
    static let mouthY: CGFloat = 0.3925   // smile centre, down from the middle

    // MARK: shared pieces

    static func bodyPath(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) -> Path {
        let size = CGSize(width: s, height: s * 1.12)
        return UShape().path(in: CGRect(origin: .zero, size: size))
            .offsetBy(dx: cx - s / 2, dy: cy - s * 0.56)
    }

    static func smilePath(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) -> Path {
        let size = CGSize(width: s * 0.17, height: s * 0.075)
        return SmileArc().path(in: CGRect(origin: .zero, size: size))
            .offsetBy(dx: cx - s * 0.085, dy: cy + s * mouthY - s * 0.0375)
    }

    static func arcPath(_ cx: CGFloat, _ cy: CGFloat, _ rad: CGFloat,
                        _ from: Double, _ to: Double) -> Path {
        var p = Path()
        let steps = 18
        for i in 0...steps {
            let a = from + (to - from) * Double(i) / Double(steps)
            let pt = CGPoint(x: cx + rad * CGFloat(cos(a)), y: cy + rad * CGFloat(sin(a)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        return p
    }

    static func star(_ ctx: inout GraphicsContext, _ x: CGFloat, _ y: CGFloat,
                     _ outer: CGFloat, _ inner: CGFloat, _ color: Color, opacity: Double = 1) {
        var p = Path()
        for i in 0..<8 {
            let a = Double(i) * Double.pi / 4 - Double.pi / 2
            let rad = (i % 2 == 1) ? inner : outer
            let pt = CGPoint(x: x + rad * CGFloat(cos(a)), y: y + rad * CGFloat(sin(a)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        ctx.fill(p, with: .color(color.opacity(opacity)))
    }

    // MARK: Blaze — rests, winds up, ignites, settles

    /// `d` is the full canvas size: the white disc, ripples and marks are all
    /// placed against it, so the whole badge is drawn here rather than layered
    /// on a SwiftUI background.
    static func blaze(_ ctx: inout GraphicsContext, _ t: Double,
                      _ cx: CGFloat, _ cy: CGFloat, _ d: CGFloat) {
        let cyc = t.truncatingRemainder(dividingBy: 1.9)

        // how worked up it is: rest, wind up, hold, settle
        let energy: Double
        switch cyc {
        case ..<0.35: energy = 0
        case ..<0.60: energy = (cyc - 0.35) / 0.25
        case ..<1.35: energy = 1
        case ..<1.60: energy = 1 - (cyc - 1.35) / 0.25
        default:      energy = 0
        }

        // the eyes only catch fire in the middle of that
        let fire: Double
        switch cyc {
        case ..<0.70: fire = 0
        case ..<0.85: fire = (cyc - 0.70) / 0.15
        case ..<1.15: fire = 1
        case ..<1.30: fire = 1 - (cyc - 1.15) / 0.15
        default:      fire = 0
        }

        let s = d * 0.44        // U width
        let ring = d * 0.355    // white disc radius

        // 1 ── ripples either side, only while it is revving
        let breathe = CGFloat(sin(t * 2 * Double.pi * 2.2)) * d * 0.010
        let rings: [(CGFloat, Double)] = [(0.395, 0.70), (0.445, 0.48), (0.492, 0.30)]
        for (offset, weight) in rings {
            let alpha = weight * energy
            if alpha < 0.02 { continue }
            let rad = d * offset + breathe
            let style = StrokeStyle(lineWidth: max(1.0, d * 0.020), lineCap: .round)
            let paint = GraphicsContext.Shading.color(Color.forestGreen.opacity(alpha))
            ctx.stroke(arcPath(cx, cy, rad, -0.62, 0.62), with: paint, style: style)
            ctx.stroke(arcPath(cx, cy, rad, Double.pi - 0.62, Double.pi + 0.62),
                       with: paint, style: style)
        }

        // 2 ── white disc
        ctx.fill(Path(ellipseIn: CGRect(x: cx - ring, y: cy - ring,
                                        width: ring * 2, height: ring * 2)),
                 with: .color(.white))

        // 3 ── the U, leaning side to side as it revs
        var g = ctx
        g.translateBy(x: cx, y: cy)
        g.rotate(by: .radians(sin(t * 2 * Double.pi * 3.2) * 0.10 * energy))
        g.translateBy(x: -cx, y: -cy)
        g.fill(bodyPath(cx, cy, s), with: .color(Color.forestGreen))

        let ey = cy + s * eyeY
        if fire < 0.999 {
            let w = s * 0.075, h = s * 0.055
            for sign in [CGFloat(-1), CGFloat(1)] {
                let rect = CGRect(x: cx + sign * s * eyeDX - w / 2, y: ey - h / 2,
                                  width: w, height: h)
                g.fill(Path(roundedRect: rect, cornerRadius: h / 2),
                       with: .color(Color.paleLime.opacity(1 - fire)))
            }
        }
        if fire > 0.001 {
            let flicker = 0.84 + sin(t * 19) * 0.16
            for sign in [CGFloat(-1), CGFloat(1)] {
                drawFlame(&g, cx + sign * s * eyeDX, ey + s * 0.03,
                          s * 0.30 * CGFloat(fire * flicker), s * 0.105,
                          opacity: fire)
            }
        }
        g.fill(smilePath(cx, cy, s), with: .color(Color.paleLime))

    }

    static func drawFlame(_ g: inout GraphicsContext, _ x: CGFloat, _ base: CGFloat,
                          _ h: CGFloat, _ w: CGFloat, opacity: Double) {
        var outer = Path()
        outer.move(to: CGPoint(x: x, y: base))
        outer.addCurve(to: CGPoint(x: x, y: base - h),
                       control1: CGPoint(x: x - w * 1.15, y: base - h * 0.30),
                       control2: CGPoint(x: x - w * 0.55, y: base - h * 0.72))
        outer.addCurve(to: CGPoint(x: x, y: base),
                       control1: CGPoint(x: x + w * 0.55, y: base - h * 0.72),
                       control2: CGPoint(x: x + w * 1.15, y: base - h * 0.30))
        g.fill(outer, with: .color(ember.opacity(0.95 * opacity)))

        var core = Path()
        core.move(to: CGPoint(x: x, y: base - h * 0.06))
        core.addCurve(to: CGPoint(x: x, y: base - h * 0.62),
                      control1: CGPoint(x: x - w * 0.50, y: base - h * 0.34),
                      control2: CGPoint(x: x - w * 0.26, y: base - h * 0.50))
        core.addCurve(to: CGPoint(x: x, y: base - h * 0.06),
                      control1: CGPoint(x: x + w * 0.26, y: base - h * 0.50),
                      control2: CGPoint(x: x + w * 0.50, y: base - h * 0.34))
        g.fill(core, with: .color(flame.opacity(0.97 * opacity)))
    }

    // MARK: Excited Wink — star eyes, a hop, and a wink

    /// `body`/`face` swap over on a dark background, where a forest-green U
    /// would disappear into the backdrop.
    static func excitedWink(_ ctx: inout GraphicsContext, _ t: Double,
                            _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat,
                            body: Color = Color.forestGreen,
                            face: Color = Color.paleLime,
                            sparks sparkColor: Color = Color.forestGreen,
                            winks: Bool = true) {
        let hop = t.truncatingRemainder(dividingBy: 1.4) / 1.4
        let jump: CGFloat = hop < 0.48 ? -CGFloat(sin(hop / 0.48 * Double.pi)) * s * 0.072 : 0
        let squash = hop < 0.48 ? 1.0 : 1.0 - sin((hop - 0.48) / 0.52 * Double.pi) * 0.045
        let tip = sin(t * 2 * Double.pi / 1.4) * 0.055
        let cycle = t.truncatingRemainder(dividingBy: 2.8)
        let winking = winks && cycle > 1.78 && cycle < 2.24

        let sparks: [(CGFloat, CGFloat)] = [(-0.448, -0.241), (0.460, -0.333),
                                            (-0.356, 0.253), (0.391, 0.172)]
        for (i, pt) in sparks.enumerated() {
            let phase = (t * 1.45 + Double(i) * 0.63).truncatingRemainder(dividingBy: 1)
            let alpha = sin(phase * Double.pi)
            if alpha < 0.06 { continue }
            star(&ctx, cx + s * pt.0, cy + s * pt.1, s * 0.043, s * 0.017,
                 sparkColor, opacity: alpha)
        }

        let pivot = cy + s * 0.56           // the U's feet, so the squash reads as landing
        var g = ctx
        g.translateBy(x: 0, y: jump)
        g.translateBy(x: cx, y: cy)
        g.rotate(by: .radians(tip))
        g.translateBy(x: -cx, y: -cy)
        g.translateBy(x: cx, y: pivot)
        g.scaleBy(x: 1 / CGFloat(squash), y: CGFloat(squash))
        g.translateBy(x: -cx, y: -pivot)

        g.fill(bodyPath(cx, cy, s), with: .color(body))

        let ey = cy + s * eyeY
        star(&g, cx + s * eyeDX, ey, s * 0.0517, s * 0.0215, face)

        if winking {
            var p = Path()
            p.move(to: CGPoint(x: cx - s * eyeDX - s * 0.046, y: ey))
            p.addQuadCurve(to: CGPoint(x: cx - s * eyeDX + s * 0.046, y: ey),
                           control: CGPoint(x: cx - s * eyeDX, y: ey + s * 0.061))
            g.stroke(p, with: .color(face),
                     style: StrokeStyle(lineWidth: s * 0.030, lineCap: .round))
        } else {
            star(&g, cx - s * eyeDX, ey, s * 0.0517, s * 0.0215, face)
        }

        g.fill(smilePath(cx, cy, s), with: .color(face))
    }

    // MARK: Talking — the mouth works away while it listens

    static func talking(_ ctx: inout GraphicsContext, _ t: Double,
                        _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat,
                        body: Color = Color.forestGreen,
                        face: Color = Color.paleLime) {
        var g = ctx
        g.translateBy(x: 0, y: CGFloat(sin(t * 2 * Double.pi / 2.1)) * s * 0.012)
        g.fill(bodyPath(cx, cy, s), with: .color(body))

        // eyes, with an occasional blink
        let blinking = t.truncatingRemainder(dividingBy: 3.6) > 3.44
        let ey = cy + s * eyeY
        let ew = s * 0.075
        let eh = blinking ? s * 0.015 : s * 0.055
        for sign in [CGFloat(-1), CGFloat(1)] {
            let rect = CGRect(x: cx + sign * s * eyeDX - ew / 2, y: ey - eh / 2,
                              width: ew, height: eh)
            g.fill(Path(roundedRect: rect, cornerRadius: eh / 2), with: .color(face))
        }

        // Two sines at unrelated speeds, so the mouth reads as speech rather
        // than an even pulse. Wide and flat when closed, rounder when open.
        let raw = 0.55 + 0.32 * sin(t * 7.9) + 0.26 * sin(t * 12.7 + 1.1)
        let open = CGFloat(min(1, max(0, raw)))
        let mw = s * (0.175 - 0.045 * open)
        let mh = s * (0.018 + 0.090 * open)
        g.fill(Path(ellipseIn: CGRect(x: cx - mw / 2, y: cy + s * mouthY - mh / 2,
                                      width: mw, height: mh)),
               with: .color(face))
    }

    // MARK: Detective — fedora and a curled handlebar, for Challenge Mode

    static func bez(_ p: [CGPoint], _ t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let a = mt * mt * mt, b = 3 * mt * mt * t, c = 3 * mt * t * t, d = t * t * t
        return CGPoint(x: a * p[0].x + b * p[1].x + c * p[2].x + d * p[3].x,
                       y: a * p[0].y + b * p[1].y + c * p[2].y + d * p[3].y)
    }

    /// A width profile swept along a curved spine: thick at the lobe beside the
    /// nose, tapering to a thin tip that lifts and hooks back inward. Built as
    /// the left half and mirrored; the spine's y is negated so it arches upward.
    static func mustachePath(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) -> Path {
        let w = s * 0.241, h = s * 0.126
        let segs: [[CGPoint]] = [
            [CGPoint(x: 0, y: 0.06), CGPoint(x: -0.32, y: -0.18),
             CGPoint(x: -0.58, y: -0.30), CGPoint(x: -0.82, y: -0.44)],
            [CGPoint(x: -0.82, y: -0.44), CGPoint(x: -1.08, y: -0.62),
             CGPoint(x: -1.04, y: -1.02), CGPoint(x: -0.66, y: -0.98)]
        ]
        var path = Path()
        for mirror in [CGFloat(1), CGFloat(-1)] {
            let steps = 36
            var spine: [(CGPoint, CGFloat)] = []
            for i in 0 ... steps {
                let u = CGFloat(i) / CGFloat(steps)
                let seg = u < 0.5 ? segs[0] : segs[1]
                let t = u < 0.5 ? u * 2 : (u - 0.5) * 2
                let q = bez(seg, t)
                spine.append((CGPoint(x: cx + mirror * q.x * w, y: cy - q.y * h), u))
            }
            var upper: [CGPoint] = [], lower: [CGPoint] = []
            for i in 0 ..< spine.count {
                let p0 = spine[max(0, i - 1)].0
                let p1 = spine[min(spine.count - 1, i + 1)].0
                var dx = p1.x - p0.x, dy = p1.y - p0.y
                let len = max(0.0001, sqrt(dx * dx + dy * dy))
                dx /= len; dy /= len
                let hw = h * (0.40 * pow(1 - spine[i].1, 1.20) + 0.028)
                upper.append(CGPoint(x: spine[i].0.x - dy * hw, y: spine[i].0.y + dx * hw))
                lower.append(CGPoint(x: spine[i].0.x + dy * hw, y: spine[i].0.y - dx * hw))
            }
            path.move(to: upper[0])
            for pt in upper.dropFirst() { path.addLine(to: pt) }
            for pt in lower.reversed() { path.addLine(to: pt) }
            path.closeSubpath()
        }
        return path
    }

    static func detective(_ ctx: inout GraphicsContext, _ t: Double,
                          _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat,
                          body: Color, face: Color, band: Color) {
        var g = ctx
        g.translateBy(x: 0, y: CGFloat(sin(t * 2 * Double.pi / 2.0)) * s * 0.013)
        g.fill(bodyPath(cx, cy, s), with: .color(body))

        // eyes narrow on a slow cycle, which reads as conspiratorial
        let squint = 0.5 + 0.5 * sin(t * 2 * Double.pi / 3.1)
        let ey = cy + s * eyeY - s * 0.052
        let rx = s * 0.0285
        let ry = rx * CGFloat(1.25 - 0.55 * squint) * 1.55
        for sign in [CGFloat(-1), CGFloat(1)] {
            let x = cx + sign * s * eyeDX
            g.fill(Path(ellipseIn: CGRect(x: x - rx, y: ey - ry, width: rx * 2, height: ry * 2)),
                   with: .color(face))
        }

        let anchor = cy + s * 0.414
        var m = g
        m.translateBy(x: cx, y: anchor)
        m.rotate(by: .radians(sin(t * 2 * Double.pi / 1.7) * 0.030))
        m.translateBy(x: -cx, y: -anchor)
        m.fill(mustachePath(cx, anchor, s), with: .color(face))

        // fedora last, so it sits in front of the U rather than behind it
        var hat = g
        hat.translateBy(x: cx, y: cy - s * 0.56)
        hat.rotate(by: .radians(-0.13))
        var crown = Path()
        crown.move(to: CGPoint(x: -s * 0.23, y: -s * 0.040))
        crown.addLine(to: CGPoint(x: -s * 0.17, y: -s * 0.236))
        crown.addLine(to: CGPoint(x: s * 0.17, y: -s * 0.236))
        crown.addLine(to: CGPoint(x: s * 0.23, y: -s * 0.040))
        crown.closeSubpath()
        hat.fill(crown, with: .color(Color(red: 28/255, green: 58/255, blue: 50/255)))
        hat.fill(Path(CGRect(x: -s * 0.23, y: -s * 0.115, width: s * 0.46, height: s * 0.058)),
                 with: .color(band))
        hat.fill(Path(roundedRect: CGRect(x: -s * 0.46, y: -s * 0.058,
                                          width: s * 0.92, height: s * 0.075),
                      cornerRadius: s * 0.034),
                 with: .color(Color(red: 38/255, green: 71/255, blue: 61/255)))
    }
}

/// Looping version of the U mascot. `.blaze` burns on the Challenge Mode button;
/// `.excitedWink` sits in Home's top-right slot. The static `UMascotView` in
/// SharedTheme stays as it is for onboarding.
struct AnimatedUMascot: View {
    enum Style { case blaze, excitedWink, talking, detective }

    var style: Style = .blaze
    /// Set on dark backgrounds: the U goes pale and the face goes forest green.
    var onDark: Bool = false
    /// Excited Wink only: off keeps both star eyes open the whole loop.
    var winks: Bool = true

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let cx = size.width / 2
                let cy = size.height / 2
                let d = min(size.width, size.height)
                switch style {
                case .blaze:
                    UMFX.blaze(&context, t, cx, cy, d)
                case .excitedWink:
                    UMFX.excitedWink(&context, t, cx, cy, d * 0.62,
                                     body: onDark ? Color.paleLime : Color.forestGreen,
                                     face: onDark ? Color.forestGreen : Color.paleLime,
                                     sparks: onDark ? Color.paleLime : Color.forestGreen,
                                     winks: winks)
                case .talking:
                    UMFX.talking(&context, t, cx, cy, d * 0.78,
                                 body: onDark ? Color.paleLime : Color.forestGreen,
                                 face: onDark ? Color.forestGreen : Color.paleLime)
                case .detective:
                    UMFX.detective(&context, t, cx, cy, d * 0.54,
                                   body: onDark ? Color.paleLime : Color.forestGreen,
                                   face: onDark ? Color(red: 12/255, green: 33/255, blue: 28/255)
                                                : Color.paleLime,
                                   band: Color.periwinkle)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
