import SwiftUI

// The U mascot dressed for each scenario, animated (drawn in one Canvas, like the Home / Challenge mascots).
//
//   about-you          waves, with a "HI" name tag          small-talk     coffee cup with rising steam
//   restaurant         waiter: bow tie, towel, wobbling tray airport        pilot cap, a little plane flies around
//   appointment        receptionist headset, calendar tick   phone-call     headset, sound waves
//   interview          glasses + tie, polite nod             presentation   microphone, spotlight
//   missing-celebrity  sunglasses + twinkling stars          suspect        detective fedora + magnifying glass
//   villains-deal      cape, eyebrows, sly grin              secret-agent   dark glasses + earpiece
//   game-master        show-host bow tie, mic, confetti
//
// `talking` makes the mouth move (while the AI voice is playing). Used on the AI conversation screen
// and on the scenario intro.

struct ScenarioMascot: View {
    let scenarioID: String
    var talking: Bool = false
    var onDark: Bool = false

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                MascotArt.draw(&ctx, size: size,
                               t: timeline.date.timeIntervalSinceReferenceDate,
                               look: MascotLook(scenarioID: scenarioID),
                               talking: talking, onDark: onDark)
            }
        }
        .accessibilityHidden(true)
    }
}

enum MascotLook {
    case hello, coffee, waiter, pilot, receptionist, phone, interview, presenter
    case celebrity, detective, villain, agent, host

    init(scenarioID: String) {
        switch scenarioID {
        case "small-talk": self = .coffee
        case "restaurant": self = .waiter
        case "airport": self = .pilot
        case "appointment": self = .receptionist
        case "phone-call": self = .phone
        case "interview": self = .interview
        case "presentation": self = .presenter
        case "missing-celebrity": self = .celebrity
        case "suspect-interview": self = .detective
        case "villains-deal": self = .villain
        case "secret-agent": self = .agent
        case "game-master": self = .host
        default: self = .hello
        }
    }
}

private enum MascotArt {
    // palette (U-Talk) + a few accent colours for props
    static let forest = Color(red: 39/255, green: 79/255, blue: 72/255)
    static let deep = Color(red: 12/255, green: 33/255, blue: 28/255)
    static let paleLime = Color(red: 237/255, green: 252/255, blue: 214/255)
    static let periwinkle = Color(red: 183/255, green: 209/255, blue: 251/255)
    static let softCyan = Color(red: 204/255, green: 241/255, blue: 253/255)
    static let charcoal = Color(red: 30/255, green: 40/255, blue: 38/255)
    static let navy = Color(red: 38/255, green: 52/255, blue: 84/255)
    static let gold = Color(red: 232/255, green: 195/255, blue: 90/255)
    static let silver = Color(red: 214/255, green: 222/255, blue: 226/255)
    static let cape = Color(red: 88/255, green: 52/255, blue: 108/255)
    static let coffee = Color(red: 120/255, green: 78/255, blue: 52/255)

    static let twoPi = 2 * Double.pi

    // MARK: Main

    static func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double,
                     look: MascotLook, talking: Bool, onDark: Bool) {
        let d = min(size.width, size.height)
        let s = d * 0.50                       // width of the U
        let cx = size.width / 2
        let cy = size.height / 2 - d * 0.03
        let body = onDark ? paleLime : forest
        let face = onDark ? deep : paleLime
        let ink = onDark ? paleLime : forest   // for lines drawn outside the body

        // idle motion: a gentle float, plus a per-look gesture
        var bob = CGFloat(sin(t * twoPi / 2.2)) * s * 0.025
        var tilt = 0.0
        switch look {
        case .hello: tilt = sin(t * twoPi / 1.1) * 0.12                       // waving
        case .interview:                                                       // polite nod every 3 s
            let p = t.truncatingRemainder(dividingBy: 3.0)
            bob += p < 0.5 ? CGFloat(sin(p / 0.5 * Double.pi)) * s * 0.05 : 0
        case .host, .celebrity:                                                // bouncy
            let p = t.truncatingRemainder(dividingBy: 1.2)
            bob -= p < 0.4 ? CGFloat(sin(p / 0.4 * Double.pi)) * s * 0.07 : 0
        case .villain: tilt = sin(t * twoPi / 3.5) * 0.05
        default: tilt = sin(t * twoPi / 3.0) * 0.03
        }

        // ---- behind the body
        switch look {
        case .presenter: spotlight(&ctx, cx, cy, s, t, color: onDark ? paleLime : periwinkle)
        case .villain: capeBehind(&ctx, cx, cy, s, t, bob)
        case .pilot: plane(&ctx, cx, cy, s, t, front: false, ink: ink)
        default: break
        }

        // ---- body (moves with bob + tilt, pivoting on its feet)
        var g = ctx
        let feet = cy + s * 0.56
        g.translateBy(x: 0, y: bob)
        g.translateBy(x: cx, y: feet)
        g.rotate(by: .radians(tilt))
        g.translateBy(x: -cx, y: -feet)
        g.fill(bodyPath(cx, cy, s), with: .color(body))

        // face
        let ey = cy + s * 0.2975
        let ex = s * 0.1075
        switch look {
        case .celebrity, .agent: sunglasses(&g, cx, ey, ex, s)
        case .villain: villainEyes(&g, cx, ey, ex, s, face)
        default: eyes(&g, cx, ey, ex, s, t, face)
        }
        if look == .interview { glasses(&g, cx, ey, ex, s, t, ink: onDark ? deep : charcoal) }
        mouth(&g, cx, cy, s, t, talking: talking, grin: look == .villain, face: face)

        // props attached to the body
        switch look {
        case .hello: nameTag(&g, cx, cy, s)
        case .waiter:
            bowTie(&g, cx, cy + s * 0.60, s, charcoal, dots: false)
            towel(&g, cx, cy, s)
            tray(&g, cx, cy, s, t)
        case .pilot: pilotCap(&g, cx, cy, s)
        case .receptionist, .phone: headset(&g, cx, cy, s, ink: onDark ? deep : charcoal)
        case .interview: necktie(&g, cx, cy, s)
        case .detective: fedora(&g, cx, cy, s)
        case .agent: earpiece(&g, cx, cy, s, t)
        case .host:
            bowTie(&g, cx, cy + s * 0.60, s, periwinkle, dots: true)
            handMic(&g, cx, cy, s, t, side: 1)
        case .presenter: handMic(&g, cx, cy, s, t, side: 1)
        default: break
        }

        // ---- in front / floating extras (not tilted with the body)
        switch look {
        case .hello: sparkles(&ctx, cx, cy, s, t, color: ink, spots: [(-0.75, -0.45), (0.72, -0.30)])
        case .coffee: coffeeCup(&ctx, cx, cy + bob, s, t, ink: ink, onDark: onDark)
        case .pilot: plane(&ctx, cx, cy, s, t, front: true, ink: ink)
        case .receptionist: calendarTick(&ctx, cx, cy, s, t)
        case .phone: soundWaves(&ctx, cx, cy, s, t, ink: ink, strong: talking)
        case .celebrity:
            sparkles(&ctx, cx, cy, s, t, color: gold,
                     spots: [(-0.78, -0.50), (0.80, -0.42), (-0.70, 0.30), (0.75, 0.40)])
        case .detective: magnifier(&ctx, cx, cy, s, t)
        case .host: confetti(&ctx, size, t)
        default: break
        }
    }

    // MARK: Body & face

    static func bodyPath(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) -> Path {
        UShape().path(in: CGRect(origin: .zero, size: CGSize(width: s, height: s * 1.12)))
            .offsetBy(dx: cx - s / 2, dy: cy - s * 0.56)
    }

    static func eyes(_ g: inout GraphicsContext, _ cx: CGFloat, _ ey: CGFloat, _ ex: CGFloat,
                     _ s: CGFloat, _ t: Double, _ face: Color) {
        let blinking = t.truncatingRemainder(dividingBy: 3.4) > 3.27
        let w = s * 0.07, h = blinking ? s * 0.014 : s * 0.075
        for sign in [CGFloat(-1), 1] {
            let r = CGRect(x: cx + sign * ex - w / 2, y: ey - h / 2, width: w, height: h)
            g.fill(Path(roundedRect: r, cornerRadius: min(w, h) / 2), with: .color(face))
        }
    }

    static func villainEyes(_ g: inout GraphicsContext, _ cx: CGFloat, _ ey: CGFloat, _ ex: CGFloat,
                            _ s: CGFloat, _ face: Color) {
        for sign in [CGFloat(-1), 1] {
            let r = CGRect(x: cx + sign * ex - s * 0.04, y: ey - s * 0.018, width: s * 0.08, height: s * 0.036)
            g.fill(Path(ellipseIn: r), with: .color(face))
            var brow = Path()
            brow.move(to: CGPoint(x: cx + sign * (ex + s * 0.06), y: ey - s * 0.075))
            brow.addLine(to: CGPoint(x: cx + sign * (ex - s * 0.05), y: ey - s * 0.035))
            g.stroke(brow, with: .color(face), style: StrokeStyle(lineWidth: s * 0.028, lineCap: .round))
        }
    }

    static func mouth(_ g: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat,
                      _ t: Double, talking: Bool, grin: Bool, face: Color) {
        let my = cy + s * 0.3925
        if talking {
            let raw = 0.55 + 0.32 * sin(t * 7.9) + 0.26 * sin(t * 12.7 + 1.1)
            let open = CGFloat(min(1, max(0, raw)))
            let w = s * (0.16 - 0.04 * open), h = s * (0.02 + 0.08 * open)
            g.fill(Path(ellipseIn: CGRect(x: cx - w / 2, y: my - h / 2, width: w, height: h)), with: .color(face))
        } else if grin {
            var p = Path()
            p.move(to: CGPoint(x: cx - s * 0.10, y: my - s * 0.02))
            p.addQuadCurve(to: CGPoint(x: cx + s * 0.10, y: my - s * 0.035),
                           control: CGPoint(x: cx + s * 0.02, y: my + s * 0.05))
            g.stroke(p, with: .color(face), style: StrokeStyle(lineWidth: s * 0.026, lineCap: .round))
        } else {
            let r = CGRect(x: cx - s * 0.085, y: my - s * 0.0375, width: s * 0.17, height: s * 0.075)
            g.fill(SmileArc().path(in: CGRect(origin: .zero, size: r.size)).offsetBy(dx: r.minX, dy: r.minY),
                   with: .color(face))
        }
    }

    // MARK: Glasses

    static func glasses(_ g: inout GraphicsContext, _ cx: CGFloat, _ ey: CGFloat, _ ex: CGFloat,
                        _ s: CGFloat, _ t: Double, ink: Color) {
        let r = s * 0.075
        for sign in [CGFloat(-1), 1] {
            let lens = CGRect(x: cx + sign * ex - r, y: ey - r * 0.85, width: r * 2, height: r * 1.7)
            g.stroke(Path(roundedRect: lens, cornerRadius: r * 0.6), with: .color(ink), lineWidth: s * 0.018)
        }
        var bridge = Path()
        bridge.move(to: CGPoint(x: cx - ex + r, y: ey - r * 0.2))
        bridge.addQuadCurve(to: CGPoint(x: cx + ex - r, y: ey - r * 0.2), control: CGPoint(x: cx, y: ey - r * 0.6))
        g.stroke(bridge, with: .color(ink), lineWidth: s * 0.016)
        // a glint sweeps across the lenses every 3 s
        let p = t.truncatingRemainder(dividingBy: 3.0)
        if p < 0.5 {
            let x = cx - ex - r + CGFloat(p / 0.5) * (2 * ex + 2 * r)
            var glint = Path()
            glint.move(to: CGPoint(x: x, y: ey - r * 0.7))
            glint.addLine(to: CGPoint(x: x - r * 0.5, y: ey + r * 0.7))
            g.stroke(glint, with: .color(.white.opacity(0.8)), lineWidth: s * 0.012)
        }
    }

    static func sunglasses(_ g: inout GraphicsContext, _ cx: CGFloat, _ ey: CGFloat, _ ex: CGFloat, _ s: CGFloat) {
        let w = s * 0.17, h = s * 0.10
        for sign in [CGFloat(-1), 1] {
            let lens = CGRect(x: cx + sign * ex - w / 2, y: ey - h / 2, width: w, height: h)
            g.fill(Path(roundedRect: lens, cornerRadius: h * 0.45), with: .color(charcoal))
            g.fill(Path(ellipseIn: CGRect(x: lens.minX + w * 0.15, y: lens.minY + h * 0.18,
                                          width: w * 0.25, height: h * 0.22)),
                   with: .color(.white.opacity(0.55)))
        }
        g.fill(Path(CGRect(x: cx - ex + w / 2, y: ey - s * 0.012, width: 2 * ex - w, height: s * 0.024)),
               with: .color(charcoal))
    }

    // MARK: Hats & headwear

    static func pilotCap(_ g: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) {
        let top = cy - s * 0.80
        let crown = CGRect(x: cx - s * 0.50, y: top, width: s * 1.0, height: s * 0.22)
        g.fill(Path(roundedRect: crown, cornerRadius: s * 0.08), with: .color(navy))
        g.fill(Path(CGRect(x: crown.minX, y: crown.maxY - s * 0.06, width: crown.width, height: s * 0.04)),
               with: .color(gold))
        g.fill(Path(ellipseIn: CGRect(x: cx - s * 0.56, y: crown.maxY - s * 0.03, width: s * 1.12, height: s * 0.08)),
               with: .color(charcoal))
        // wings badge
        var wings = Path()
        wings.move(to: CGPoint(x: cx - s * 0.13, y: top + s * 0.09))
        wings.addLine(to: CGPoint(x: cx, y: top + s * 0.12))
        wings.addLine(to: CGPoint(x: cx + s * 0.13, y: top + s * 0.09))
        wings.addLine(to: CGPoint(x: cx, y: top + s * 0.15))
        wings.closeSubpath()
        g.fill(wings, with: .color(gold))
        g.fill(Path(ellipseIn: CGRect(x: cx - s * 0.03, y: top + s * 0.085, width: s * 0.06, height: s * 0.06)),
               with: .color(gold))
    }

    static func fedora(_ g: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) {
        var hat = g
        hat.translateBy(x: cx, y: cy - s * 0.58)
        hat.rotate(by: .radians(-0.12))
        var crown = Path()
        crown.move(to: CGPoint(x: -s * 0.30, y: -s * 0.02))
        crown.addLine(to: CGPoint(x: -s * 0.22, y: -s * 0.26))
        crown.addQuadCurve(to: CGPoint(x: s * 0.22, y: -s * 0.26), control: CGPoint(x: 0, y: -s * 0.20))
        crown.addLine(to: CGPoint(x: s * 0.30, y: -s * 0.02))
        crown.closeSubpath()
        hat.fill(crown, with: .color(Color(red: 92/255, green: 74/255, blue: 58/255)))
        hat.fill(Path(CGRect(x: -s * 0.29, y: -s * 0.10, width: s * 0.58, height: s * 0.06)), with: .color(charcoal))
        hat.fill(Path(roundedRect: CGRect(x: -s * 0.55, y: -s * 0.045, width: s * 1.10, height: s * 0.075),
                      cornerRadius: s * 0.035),
                 with: .color(Color(red: 74/255, green: 58/255, blue: 45/255)))
    }

    static func headset(_ g: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, ink: Color) {
        let armTop = cy - s * 0.50
        var band = Path()
        band.move(to: CGPoint(x: cx - s * 0.345, y: armTop))
        band.addQuadCurve(to: CGPoint(x: cx + s * 0.345, y: armTop), control: CGPoint(x: cx, y: cy - s * 0.98))
        g.stroke(band, with: .color(ink), style: StrokeStyle(lineWidth: s * 0.05, lineCap: .round))
        for sign in [CGFloat(-1), 1] {
            let ear = CGRect(x: cx + sign * s * 0.345 - s * 0.10, y: armTop - s * 0.05, width: s * 0.20, height: s * 0.16)
            g.fill(Path(roundedRect: ear, cornerRadius: s * 0.07), with: .color(ink))
            g.fill(Path(roundedRect: ear.insetBy(dx: s * 0.03, dy: s * 0.03), cornerRadius: s * 0.04),
                   with: .color(periwinkle))
        }
        var boom = Path()
        boom.move(to: CGPoint(x: cx - s * 0.40, y: armTop + s * 0.08))
        boom.addQuadCurve(to: CGPoint(x: cx - s * 0.16, y: cy + s * 0.42), control: CGPoint(x: cx - s * 0.52, y: cy + s * 0.38))
        g.stroke(boom, with: .color(ink), style: StrokeStyle(lineWidth: s * 0.025, lineCap: .round))
        g.fill(Path(ellipseIn: CGRect(x: cx - s * 0.19, y: cy + s * 0.39, width: s * 0.07, height: s * 0.06)),
               with: .color(ink))
    }

    static func earpiece(_ g: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ t: Double) {
        let ear = CGPoint(x: cx + s * 0.45, y: cy - s * 0.30)
        g.fill(Path(ellipseIn: CGRect(x: ear.x - s * 0.035, y: ear.y - s * 0.035, width: s * 0.07, height: s * 0.07)),
               with: .color(charcoal))
        var wire = Path()
        wire.move(to: ear)
        for i in 1...6 {   // a coiled wire down the side
            let y = ear.y + CGFloat(i) * s * 0.08
            wire.addQuadCurve(to: CGPoint(x: ear.x, y: y),
                              control: CGPoint(x: ear.x + (i.isMultiple(of: 2) ? 1 : -1) * s * 0.05, y: y - s * 0.04))
        }
        g.stroke(wire, with: .color(charcoal.opacity(0.8)), lineWidth: s * 0.014)
        // signal blink
        let on = t.truncatingRemainder(dividingBy: 1.2) < 0.3
        if on {
            g.fill(Path(ellipseIn: CGRect(x: ear.x + s * 0.06, y: ear.y - s * 0.10, width: s * 0.04, height: s * 0.04)),
                   with: .color(Color.red.opacity(0.8)))
        }
    }

    // MARK: Clothes

    static func bowTie(_ g: inout GraphicsContext, _ cx: CGFloat, _ y: CGFloat, _ s: CGFloat,
                       _ color: Color, dots: Bool) {
        let w = s * 0.16, h = s * 0.10
        for sign in [CGFloat(-1), 1] {
            var wing = Path()
            wing.move(to: CGPoint(x: cx, y: y))
            wing.addLine(to: CGPoint(x: cx + sign * w, y: y - h))
            wing.addQuadCurve(to: CGPoint(x: cx + sign * w, y: y + h), control: CGPoint(x: cx + sign * w * 1.15, y: y))
            wing.closeSubpath()
            g.fill(wing, with: .color(color))
            if dots {
                g.fill(Path(ellipseIn: CGRect(x: cx + sign * w * 0.6 - s * 0.015, y: y - s * 0.015,
                                              width: s * 0.03, height: s * 0.03)), with: .color(.white))
            }
        }
        g.fill(Path(roundedRect: CGRect(x: cx - s * 0.035, y: y - s * 0.045, width: s * 0.07, height: s * 0.09),
                    cornerRadius: s * 0.02),
               with: .color(color))
    }

    static func necktie(_ g: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) {
        let top = cy + s * 0.53
        // white collar points
        for sign in [CGFloat(-1), 1] {
            var collar = Path()
            collar.move(to: CGPoint(x: cx, y: top + s * 0.02))
            collar.addLine(to: CGPoint(x: cx + sign * s * 0.15, y: top - s * 0.03))
            collar.addLine(to: CGPoint(x: cx + sign * s * 0.10, y: top + s * 0.10))
            collar.closeSubpath()
            g.fill(collar, with: .color(.white))
        }
        var knot = Path()
        knot.move(to: CGPoint(x: cx - s * 0.045, y: top))
        knot.addLine(to: CGPoint(x: cx + s * 0.045, y: top))
        knot.addLine(to: CGPoint(x: cx + s * 0.03, y: top + s * 0.07))
        knot.addLine(to: CGPoint(x: cx - s * 0.03, y: top + s * 0.07))
        knot.closeSubpath()
        g.fill(knot, with: .color(navy))
        var tie = Path()
        tie.move(to: CGPoint(x: cx - s * 0.03, y: top + s * 0.07))
        tie.addLine(to: CGPoint(x: cx + s * 0.03, y: top + s * 0.07))
        tie.addLine(to: CGPoint(x: cx + s * 0.07, y: top + s * 0.30))
        tie.addLine(to: CGPoint(x: cx, y: top + s * 0.37))
        tie.addLine(to: CGPoint(x: cx - s * 0.07, y: top + s * 0.30))
        tie.closeSubpath()
        g.fill(tie, with: .color(navy))
        for i in 0..<3 {  // stripes
            let y = top + s * (0.13 + 0.07 * CGFloat(i))
            var stripe = Path()
            stripe.move(to: CGPoint(x: cx - s * 0.05, y: y))
            stripe.addLine(to: CGPoint(x: cx + s * 0.05, y: y - s * 0.04))
            var clipped = g
            clipped.clip(to: tie)
            clipped.stroke(stripe, with: .color(periwinkle), lineWidth: s * 0.018)
        }
    }

    static func towel(_ g: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) {
        let x = cx - s * 0.345
        var cloth = Path()
        cloth.move(to: CGPoint(x: x - s * 0.17, y: cy - s * 0.20))
        cloth.addLine(to: CGPoint(x: x + s * 0.17, y: cy - s * 0.20))
        cloth.addLine(to: CGPoint(x: x + s * 0.13, y: cy + s * 0.14))
        cloth.addLine(to: CGPoint(x: x - s * 0.13, y: cy + s * 0.10))
        cloth.closeSubpath()
        g.fill(cloth, with: .color(.white))
        g.stroke(cloth, with: .color(silver), lineWidth: s * 0.01)
        for i in 1...2 {
            var line = Path()
            let y = cy - s * 0.20 + CGFloat(i) * s * 0.10
            line.move(to: CGPoint(x: x - s * 0.15, y: y))
            line.addLine(to: CGPoint(x: x + s * 0.15, y: y))
            g.stroke(line, with: .color(periwinkle), lineWidth: s * 0.014)
        }
    }

    static func tray(_ g: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ t: Double) {
        var tr = g
        let hand = CGPoint(x: cx + s * 0.345, y: cy - s * 0.60)
        tr.translateBy(x: hand.x, y: hand.y)
        tr.rotate(by: .radians(sin(t * twoPi / 1.6) * 0.10))   // balancing wobble
        tr.fill(Path(ellipseIn: CGRect(x: -s * 0.30, y: -s * 0.04, width: s * 0.60, height: s * 0.08)),
                with: .color(silver))
        var dome = Path()
        dome.addArc(center: CGPoint(x: 0, y: -s * 0.02), radius: s * 0.17,
                    startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        dome.closeSubpath()
        tr.fill(dome, with: .color(Color(red: 236/255, green: 240/255, blue: 242/255)))
        tr.fill(Path(ellipseIn: CGRect(x: -s * 0.03, y: -s * 0.23, width: s * 0.06, height: s * 0.05)),
                with: .color(silver))
        tr.fill(Path(ellipseIn: CGRect(x: -s * 0.10, y: -s * 0.15, width: s * 0.05, height: s * 0.08)),
                with: .color(.white.opacity(0.9)))
    }

    static func nameTag(_ g: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) {
        let r = CGRect(x: cx - s * 0.345 - s * 0.15, y: cy - s * 0.18, width: s * 0.30, height: s * 0.20)
        g.fill(Path(roundedRect: r, cornerRadius: s * 0.04), with: .color(.white))
        g.fill(Path(roundedRect: CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height * 0.38),
                    cornerRadius: s * 0.04),
               with: .color(periwinkle))
        g.draw(Text("HI").font(.system(size: s * 0.09, weight: .heavy, design: .rounded)).foregroundColor(forest),
               at: CGPoint(x: r.midX, y: r.minY + r.height * 0.68))
    }

    static func handMic(_ g: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat,
                        _ t: Double, side: CGFloat) {
        var m = g
        let base = CGPoint(x: cx + side * s * 0.62, y: cy + s * 0.62)
        m.translateBy(x: base.x, y: base.y)
        m.rotate(by: .radians(-0.55 * Double(side) + sin(t * twoPi / 2.0) * 0.06))
        m.fill(Path(roundedRect: CGRect(x: -s * 0.035, y: -s * 0.38, width: s * 0.07, height: s * 0.38),
                    cornerRadius: s * 0.03),
               with: .color(charcoal))
        m.fill(Path(ellipseIn: CGRect(x: -s * 0.08, y: -s * 0.52, width: s * 0.16, height: s * 0.16)),
               with: .color(silver))
        for i in 0..<3 {
            var grill = Path()
            let y = -s * 0.48 + CGFloat(i) * s * 0.035
            grill.move(to: CGPoint(x: -s * 0.06, y: y))
            grill.addLine(to: CGPoint(x: s * 0.06, y: y))
            m.stroke(grill, with: .color(charcoal.opacity(0.35)), lineWidth: s * 0.008)
        }
    }

    // MARK: Extras around the U

    static func coffeeCup(_ ctx: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ t: Double,
                          ink: Color, onDark: Bool) {
        let c = CGPoint(x: cx + s * 0.68, y: cy + s * 0.32)
        var cup = ctx
        cup.translateBy(x: c.x, y: c.y)
        cup.rotate(by: .radians(sin(t * twoPi / 3.0) * 0.05))
        let body = CGRect(x: -s * 0.12, y: -s * 0.12, width: s * 0.24, height: s * 0.22)
        let handle = Path(ellipseIn: CGRect(x: s * 0.08, y: -s * 0.07, width: s * 0.12, height: s * 0.11))
        if !onDark {   // outline so the white cup shows on pale backgrounds
            cup.stroke(handle, with: .color(ink), lineWidth: s * 0.05)
            cup.fill(Path(roundedRect: body.insetBy(dx: -s * 0.015, dy: -s * 0.015), cornerRadius: s * 0.06),
                     with: .color(ink))
        }
        cup.fill(Path(roundedRect: body, cornerRadius: s * 0.05), with: .color(.white))
        cup.stroke(handle, with: .color(.white), lineWidth: s * 0.03)
        cup.fill(Path(ellipseIn: CGRect(x: -s * 0.11, y: -s * 0.145, width: s * 0.22, height: s * 0.05)),
                 with: .color(coffee))
        cup.fill(Path(CGRect(x: -s * 0.12, y: -s * 0.01, width: s * 0.24, height: s * 0.04)), with: .color(periwinkle))
        // steam: three wavy lines drifting up and fading
        for i in 0..<3 {
            let phase = (t * 0.6 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
            let x0 = CGFloat(i - 1) * s * 0.06
            var steam = Path()
            for j in 0...10 {
                let u = CGFloat(j) / 10
                let y = -s * 0.17 - u * s * 0.22 - CGFloat(phase) * s * 0.10
                let x = x0 + CGFloat(sin(Double(u) * 6 + t * 3 + Double(i))) * s * 0.025
                if j == 0 { steam.move(to: CGPoint(x: x, y: y)) } else { steam.addLine(to: CGPoint(x: x, y: y)) }
            }
            cup.stroke(steam, with: .color((onDark ? Color.white : ink).opacity(0.75 * (1 - phase))),
                       style: StrokeStyle(lineWidth: s * 0.022, lineCap: .round))
        }
    }

    static func plane(_ ctx: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat,
                      _ t: Double, front: Bool, ink: Color) {
        let a = t * twoPi / 4.0
        let inFront = sin(a) > 0
        guard inFront == front else { return }
        let p = CGPoint(x: cx + s * 0.85 * CGFloat(cos(a)), y: cy - s * 0.15 + s * 0.28 * CGFloat(sin(a)))
        let heading = atan2(0.28 * cos(a), -0.85 * sin(a))
        var pl = ctx
        pl.translateBy(x: p.x, y: p.y)
        pl.rotate(by: .radians(heading))
        let k = s * (front ? 0.20 : 0.15)
        pl.opacity = front ? 1 : 0.55
        pl.fill(Path(roundedRect: CGRect(x: -k * 0.6, y: -k * 0.09, width: k * 1.2, height: k * 0.18),
                     cornerRadius: k * 0.09),
                with: .color(ink == paleLime ? .white : ink))
        var wing = Path()
        wing.move(to: CGPoint(x: k * 0.05, y: 0))
        wing.addLine(to: CGPoint(x: -k * 0.2, y: -k * 0.5))
        wing.addLine(to: CGPoint(x: -k * 0.3, y: -k * 0.5))
        wing.addLine(to: CGPoint(x: -k * 0.15, y: 0))
        wing.addLine(to: CGPoint(x: -k * 0.3, y: k * 0.5))
        wing.addLine(to: CGPoint(x: -k * 0.2, y: k * 0.5))
        wing.closeSubpath()
        pl.fill(wing, with: .color(ink == paleLime ? periwinkle : navy))
    }

    static func calendarTick(_ ctx: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ t: Double) {
        let p = t.truncatingRemainder(dividingBy: 3.0)
        let pop = p < 0.3 ? 1 + 0.25 * sin(p / 0.3 * Double.pi) : 1
        var cal = ctx
        cal.translateBy(x: cx + s * 0.72, y: cy - s * 0.42)
        cal.scaleBy(x: CGFloat(pop), y: CGFloat(pop))
        let r = CGRect(x: -s * 0.14, y: -s * 0.13, width: s * 0.28, height: s * 0.26)
        cal.fill(Path(roundedRect: r.insetBy(dx: -s * 0.012, dy: -s * 0.012), cornerRadius: s * 0.05),
                 with: .color(forest.opacity(0.35)))
        cal.fill(Path(roundedRect: r, cornerRadius: s * 0.04), with: .color(.white))
        cal.fill(Path(roundedRect: CGRect(x: r.minX, y: r.minY, width: r.width, height: s * 0.07), cornerRadius: s * 0.04),
                 with: .color(periwinkle))
        if p > 0.15 {
            var tick = Path()
            tick.move(to: CGPoint(x: -s * 0.07, y: s * 0.03))
            tick.addLine(to: CGPoint(x: -s * 0.015, y: s * 0.08))
            tick.addLine(to: CGPoint(x: s * 0.08, y: -s * 0.03))
            cal.stroke(tick, with: .color(forest), style: StrokeStyle(lineWidth: s * 0.03, lineCap: .round, lineJoin: .round))
        }
    }

    static func soundWaves(_ ctx: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat,
                           _ t: Double, ink: Color, strong: Bool) {
        for i in 0..<3 {
            let phase = (t * (strong ? 1.6 : 0.9) + Double(i) / 3).truncatingRemainder(dividingBy: 1)
            let r = s * (0.18 + 0.30 * CGFloat(phase))
            for sign in [CGFloat(-1), 1] {
                var arc = Path()
                let c = CGPoint(x: cx + sign * s * 0.55, y: cy - s * 0.35)
                let start = sign > 0 ? -0.6 : Double.pi - 0.6
                arc.addArc(center: c, radius: r, startAngle: .radians(start), endAngle: .radians(start + 1.2), clockwise: false)
                ctx.stroke(arc, with: .color(ink.opacity(0.7 * (1 - phase))),
                           style: StrokeStyle(lineWidth: s * 0.025, lineCap: .round))
            }
        }
    }

    static func spotlight(_ ctx: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ t: Double,
                          color: Color) {
        var beam = Path()
        beam.move(to: CGPoint(x: cx - s * 0.12, y: cy - s * 1.1))
        beam.addLine(to: CGPoint(x: cx + s * 0.12, y: cy - s * 1.1))
        beam.addLine(to: CGPoint(x: cx + s * 0.75, y: cy + s * 0.70))
        beam.addLine(to: CGPoint(x: cx - s * 0.75, y: cy + s * 0.70))
        beam.closeSubpath()
        let glow = 0.20 + 0.10 * sin(t * twoPi / 2.5)
        ctx.fill(beam, with: .linearGradient(Gradient(colors: [color.opacity(glow + 0.25), color.opacity(0)]),
                                             startPoint: CGPoint(x: cx, y: cy - s * 1.1),
                                             endPoint: CGPoint(x: cx, y: cy + s * 0.70)))
    }

    static func capeBehind(_ ctx: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat,
                           _ t: Double, _ bob: CGFloat) {
        let flutter = CGFloat(sin(t * twoPi / 1.4)) * s * 0.06
        var capePath = Path()
        capePath.move(to: CGPoint(x: cx - s * 0.40, y: cy - s * 0.35 + bob))
        capePath.addLine(to: CGPoint(x: cx + s * 0.40, y: cy - s * 0.35 + bob))
        capePath.addQuadCurve(to: CGPoint(x: cx + s * 0.80 + flutter, y: cy + s * 0.75),
                              control: CGPoint(x: cx + s * 0.75, y: cy))
        capePath.addQuadCurve(to: CGPoint(x: cx - s * 0.80 + flutter, y: cy + s * 0.75),
                              control: CGPoint(x: cx, y: cy + s * 0.62 + flutter))
        capePath.addQuadCurve(to: CGPoint(x: cx - s * 0.40, y: cy - s * 0.35 + bob),
                              control: CGPoint(x: cx - s * 0.75, y: cy))
        ctx.fill(capePath, with: .color(cape))
    }

    static func magnifier(_ ctx: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ t: Double) {
        let a = t * twoPi / 3.0
        let c = CGPoint(x: cx + s * 0.62 + CGFloat(cos(a)) * s * 0.06, y: cy + s * 0.10 + CGFloat(sin(a)) * s * 0.06)
        var handle = Path()
        handle.move(to: CGPoint(x: c.x + s * 0.09, y: c.y + s * 0.09))
        handle.addLine(to: CGPoint(x: c.x + s * 0.24, y: c.y + s * 0.26))
        ctx.stroke(handle, with: .color(Color(red: 92/255, green: 74/255, blue: 58/255)),
                   style: StrokeStyle(lineWidth: s * 0.05, lineCap: .round))
        let lens = CGRect(x: c.x - s * 0.13, y: c.y - s * 0.13, width: s * 0.26, height: s * 0.26)
        ctx.fill(Path(ellipseIn: lens), with: .color(softCyan.opacity(0.45)))
        ctx.stroke(Path(ellipseIn: lens), with: .color(gold), lineWidth: s * 0.035)
    }

    static func sparkles(_ ctx: inout GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ t: Double,
                         color: Color, spots: [(CGFloat, CGFloat)]) {
        for (i, pt) in spots.enumerated() {
            let phase = (t * 1.1 + Double(i) * 0.37).truncatingRemainder(dividingBy: 1)
            let alpha = sin(phase * Double.pi)
            guard alpha > 0.05 else { continue }
            let x = cx + s * pt.0, y = cy + s * pt.1
            let outer = s * 0.06 * CGFloat(0.6 + 0.4 * alpha), inner = outer * 0.38
            var star = Path()
            for k in 0..<8 {
                let ang = Double(k) * Double.pi / 4 - Double.pi / 2
                let r = k.isMultiple(of: 2) ? outer : inner
                let p = CGPoint(x: x + r * CGFloat(cos(ang)), y: y + r * CGFloat(sin(ang)))
                if k == 0 { star.move(to: p) } else { star.addLine(to: p) }
            }
            star.closeSubpath()
            ctx.fill(star, with: .color(color.opacity(alpha)))
        }
    }

    static func confetti(_ ctx: inout GraphicsContext, _ size: CGSize, _ t: Double) {
        let colors = [paleLime, periwinkle, softCyan, gold]
        for i in 0..<14 {
            let speed = 0.25 + Double(i % 5) * 0.04
            let phase = (t * speed + Double(i) * 0.137).truncatingRemainder(dividingBy: 1)
            let x = size.width * CGFloat((Double(i) * 0.071 + 0.03).truncatingRemainder(dividingBy: 1))
                + CGFloat(sin(t * 2 + Double(i))) * 6
            let y = size.height * CGFloat(phase) - 6
            var piece = ctx
            piece.translateBy(x: x, y: y)
            piece.rotate(by: .radians(t * 3 + Double(i)))
            piece.fill(Path(CGRect(x: -3, y: -1.5, width: 6, height: 3)),
                       with: .color(colors[i % colors.count].opacity(0.9)))
        }
    }
}

#Preview {
    let ids = ["about-you", "small-talk", "restaurant", "airport", "appointment", "phone-call", "interview",
               "presentation", "missing-celebrity", "suspect-interview", "villains-deal", "secret-agent", "game-master"]
    return ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
            ForEach(ids, id: \.self) { id in
                VStack {
                    ScenarioMascot(scenarioID: id).frame(width: 150, height: 150)
                    Text(id).font(.caption)
                }
            }
        }
    }
}
